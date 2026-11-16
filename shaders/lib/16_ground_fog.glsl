#ifndef GRAFUN_GROUND_FOG_GLSL
#define GRAFUN_GROUND_FOG_GLSL

#ifndef GRAFUN_VERTEX_STAGE

// ============================================================
// GRAFUN GROUND FOG
// Independent from Atomfog() / SkyViewLUT.
// - Rayleigh and Mie use separate 1-T contributions.
// - The legacy local fog is height-only (no horizontal FBM).
// - Local fog optical depth uses 3-point Gauss-Legendre quadrature.
// - Sun shadow visibility is sampled exponentially and arithmetically averaged.
// - Local-fog higher-order scattering uses the cached generic environment light
//   from colortex14(3,0), divided by 4PI and scaled by the legacy light factor.
// - Ozone is intentionally excluded from this ground-fog model.
// ============================================================

const float GF_LOCAL_FOG_HEIGHT = 80.0;
const float GF_LOCAL_FOG_REFERENCE_SIGMA = 0.0005;
const float GF_LOCAL_FOG_HEIGHT_FALLOFF = 0.05;
const int GF_GROUND_FOG_SHADOW_STEPS = 40;

// Generic sphere intersection in the same camera-relative world space used
// by earth_core_position. rd must be normalized.
vec2 gfGroundFogSphereRoots(vec3 ro, vec3 rd, float radius)
{
    vec3 oc = ro - earth_core_position;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - radius * radius;
    float discriminant = b * b - c;

    if (discriminant < 0.0)
        return vec2(-1.0);

    float s = sqrt(max(discriminant, 0.0));
    return vec2(-b - s, -b + s);
}

// Local fog density retained from the simplified legacy profile.
// Horizontal FBM / Perlin modulation and wind animation are absent.
float gfGroundFogLocalDensity(vec3 p, vec3 sunDir)
{
    float altitude = length(p - earth_core_position) - MC_r;

    // The local fog exists only in the first 80 world units above the crust.
    if (altitude < -0.1 || altitude > GF_LOCAL_FOG_HEIGHT)
        return 0.0;

    float h = max(altitude, 0.0);
    vec3 up = normalize(p - earth_core_position);
    float sunMu = clamp(dot(up, sunDir), -1.0, 1.0);
    float horizonFactor = clamp(1.0 - sunMu * sunMu, 0.0, 1.0);

    return GF_LOCAL_FOG_REFERENCE_SIGMA
         * pow(horizonFactor, 10.0)
         * exp(-GF_LOCAL_FOG_HEIGHT_FALLOFF * h);
}

// Integrate local fog only over the part of the ray that intersects the
// near-ground 80-unit shell. Clipping first prevents a long atmosphere ray
// from missing this thin layer with its quadrature nodes.
float gfGroundFogLocalOpticalDepth(
    vec3 rayOrigin,
    vec3 rayDir,
    float pathStartT,
    float pathEndT,
    vec3 sunDir
)
{
    vec2 shellHit = gfGroundFogSphereRoots(
        rayOrigin,
        rayDir,
        MC_r + GF_LOCAL_FOG_HEIGHT
    );

    if (shellHit.y <= 0.0)
        return 0.0;

    float localStartT = max(pathStartT, max(shellHit.x, 0.0));
    float localEndT = min(pathEndT, shellHit.y);
    if (localEndT <= localStartT)
        return 0.0;

    float localLength = localEndT - localStartT;

    // 3-point Gauss-Legendre on [0, 1].
    // Nodes: 0.1127016654, 0.5, 0.8872983346.
    // Weights: 5/18, 8/18, 5/18.
    vec3 p0 = rayOrigin + rayDir * (localStartT + localLength * 0.1127016654);
    vec3 p1 = rayOrigin + rayDir * (localStartT + localLength * 0.5);
    vec3 p2 = rayOrigin + rayDir * (localStartT + localLength * 0.8872983346);

    float d0 = gfGroundFogLocalDensity(p0, sunDir);
    float d1 = gfGroundFogLocalDensity(p1, sunDir);
    float d2 = gfGroundFogLocalDensity(p2, sunDir);

    return localLength * (
          (5.0 / 18.0) * d0
        + (8.0 / 18.0) * d1
        + (5.0 / 18.0) * d2
    );
}

// One shadow-map visibility lookup. Outside the shadow frustum is treated as
// lit, matching the existing Grafun shadow convention.
vec3 gfGroundFogShadowAt(vec3 worldPosition)
{
    vec3 shadowViewPosition =
        (shadowModelView * vec4(worldPosition, 1.0)).xyz;
    vec4 shadowClipPosition =
        shadowProjection * vec4(shadowViewPosition, 1.0);

    if (shadowClipPosition.w <= 1e-7)
        return vec3(1.0);

    shadowClipPosition.z -= 0.000001;
    shadowClipPosition.xyz = distortShadowClipPos(shadowClipPosition.xyz);

    vec3 shadowNDC = shadowClipPosition.xyz / shadowClipPosition.w;
    if (any(greaterThan(abs(shadowNDC), vec3(1.0))))
        return vec3(1.0);

    return getShadow(shadowNDC * 0.5 + 0.5);
}

// Exponential shadow stepping followed by a plain arithmetic mean.
// No density weighting, Gauss weights, or temporal jitter are used here.
vec3 gfGroundFogAverageShadow(vec3 startPos, vec3 endPos)
{
    vec3 visibilitySum = vec3(0.0);

    for (int i = 0; i < GF_GROUND_FOG_SHADOW_STEPS; ++i)
    {
        float u = (float(i) + 0.5) / float(GF_GROUND_FOG_SHADOW_STEPS);
        float t = (pow(11.0, u) - 1.0) * 0.1;
        vec3 samplePosition = mix(startPos, endPos, t);
        visibilitySum += gfGroundFogShadowAt(samplePosition);
    }

    return visibilitySum / float(GF_GROUND_FOG_SHADOW_STEPS);
}

// Cached full-environment light from composite.fsh.
// Pixel (3,0) stores the once-per-frame generic environment-light cache.
vec3 gfGroundFogGenericEnvironmentLight()
{
    return texelFetch(colortex14, ivec2(3, 0), 0).rgb;
}

// Composite ground fog over an opaque/translucent scene segment.
// rayOrigin and surfacePosition must share camera-relative world coordinates.
vec3 groundFog(
    vec3 sceneColor,
    vec3 rayOrigin,
    vec3 surfacePosition,
    float light
)
{
#if GF_GROUND_FOG_ENABLED == 0
    // The original pack bypassed ground fog with an unconditional return.
    // Keep that appearance, but avoid evaluating its unused sky cache.
    return sceneColor;
#else
    vec3 rayVector = surfacePosition - rayOrigin;
    float rayLength = length(rayVector);
    if (rayLength <= 1e-4)
        return sceneColor;

    vec3 rayDir = rayVector / rayLength;
    float epsilon = max(1e-3, abs(MC_r) * 1e-8);

    // Do not integrate through the solid Earth when the origin is underground.
    float originRadius = length(rayOrigin - earth_core_position);
    if (originRadius < MC_r - epsilon)
        return sceneColor;

    // The integration interval must lie inside the atmosphere shell.
    vec2 atmosphereHit = intersectEarth(rayDir, rayOrigin);
    if (atmosphereHit.y <= 0.0)
        return sceneColor;

    float pathStartT = max(atmosphereHit.x, 0.0);
    float pathEndT = min(rayLength, atmosphereHit.y);

    // Stop at the first crust intersection if it occurs before the depth hit.
    vec2 crustHit = intersectGround(rayOrigin, rayDir);
    if (crustHit.x >= pathStartT && crustHit.x < pathEndT)
        pathEndT = crustHit.x;

    if (pathEndT - pathStartT <= 2.0 * epsilon)
        return sceneColor;

    float safeStartT = pathStartT + epsilon;
    float safeEndT = pathEndT - epsilon;
    vec3 pathStart = rayOrigin + rayDir * safeStartT;
    vec3 pathEnd = rayOrigin + rayDir * safeEndT;
    float pathLength = safeEndT - safeStartT;
    vec3 midpoint = rayOrigin + rayDir * (0.5 * (safeStartT + safeEndT));

    // Finite-segment Rayleigh/Mie optical depth from the existing LUT.
    // getOpticalDepth() contains Rayleigh RGB and Mie alpha only; ozone is
    // deliberately not queried in this independent ground-fog function.
    vec4 tauAtStart = getOpticalDepth(pathStart, rayDir);
    vec4 tauAtEnd = getOpticalDepth(pathEnd, rayDir);
    vec4 segmentTau = tauAtStart - tauAtEnd;

    // LUT subtraction can become negative because of interpolation/
    // precision error. Recompute the whole ground-fog segment with the
    // existing two-point quadrature instead of clamping negative tau to zero.
    if (any(lessThan(segmentTau, vec4(0.0))))
    {
        segmentTau = grafunSegmentTau(midpoint, rayDir, pathLength);
    }


    vec3 transmittanceRayleigh = exp(-segmentTau.rgb);
    float transmittanceMie = exp(-segmentTau.a);

    vec3 sunDir = normalize(sun_world);
    float localFogTau = gfGroundFogLocalOpticalDepth(
        rayOrigin,
        rayDir,
        safeStartT,
        safeEndT,
        sunDir
    );
    float transmittanceLocal = exp(-localFogTau);

    // One solar source sample at the midpoint of the effective path.
    vec4 sunTau = getOpticalDepth(midpoint, sunDir);
    vec3 sunTransmittance = exp(-(sunTau.rgb + vec3(sunTau.a)));
    float sunGeometricVisibility = sunCanReachPoint(midpoint, sunDir);
    vec3 midpointSunLight = light_color * sunTransmittance * sunGeometricVisibility;

    // Shadow visibility is evaluated separately from optical depth.
    vec3 averageShadow = gfGroundFogAverageShadow(pathStart, pathEnd);
    vec3 incidentLight = midpointSunLight * averageShadow;

    float cosTheta = clamp(dot(rayDir, sunDir), -1.0, 1.0);
    float phaseRayleigh = rayleighPhase(cosTheta);
    float phaseMie = miePhase(cosTheta);

    // Deliberate independent-species approximation:
    // each species contributes its own (1-T)*phase term; cross-extinction
    // between Rayleigh, Mie and local fog is not included in the source terms.
    vec3 scatterRayleigh = (vec3(1.0) - transmittanceRayleigh) * phaseRayleigh;
    vec3 scatterMie = vec3(1.0 - transmittanceMie) * phaseMie;
    vec3 scatterLocal = vec3(1.0 - transmittanceLocal) * phaseMie;

    // Local-fog higher-order / ambient term:
    // use the cached generic environment light as the illumination source.
    // Per the requested model, divide that cached sky/environment light by 4PI
    // and scale by the local optical depth and the legacy light factor.
    vec3 genericEnvironmentLight = gfGroundFogGenericEnvironmentLight();
    vec3 localFogHighOrder =
        genericEnvironmentLight * (localFogTau / (4.0 * PI)) * light;

    vec3 inScatteredLight = incidentLight *
        (scatterRayleigh + scatterMie + scatterLocal)
        + localFogHighOrder;

    // Background transmission combines all three independent extinction terms.
    vec3 totalTransmittance =
        transmittanceRayleigh * transmittanceMie * transmittanceLocal;

    return sceneColor * totalTransmittance + inScatteredLight;
#endif
}

#endif // !GRAFUN_VERTEX_STAGE

#endif // GRAFUN_GROUND_FOG_GLSL
