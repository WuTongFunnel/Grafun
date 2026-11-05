#version 450 compatibility
#include "/lib/function.glsl"
#include "/lib/13_water_surface.glsl"

uniform sampler3D atom;
in vec2 texcoord;

/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 finalcolor;

// =============================================================
// Grafun: Pixel-grid 2D DDA Screen Space Reflections
// Coordinate conventions:
//   worldPos: camera-relative WORLD coordinates
//   rayVS: camera/view coordinates (forward = negative Z)
//   P0/P1: screen PIXELS; DDA visits each crossed pixel cell
//   k=1/clip.w, Q=viewPos*k -> perspective-correct interpolation
// =============================================================
vec4 grafunSSR2DDDA(vec3 worldPos, vec3 normal, vec3 reflectionDir)
{
    const float BIG = 1e30;
    const float MIN_RAY_Z_EPS = 0.001;

    // The old SSR_STEP_SIZE now determines WORLD RAY REACH, not pixel stride.
    float maxDistance = max(SSR_STEP_SIZE, 0.001) * float(SSR_MAX_STEPS);
    float thickness = max(SSR_THICKNESS, 0.001);
    vec2 resolution = vec2(viewWidth, viewHeight);

    // Reject rays going into the solid surface.
    if (dot(reflectionDir, normal) <= 1e-5)
        return vec4(0.0);

    // Offset the start to prevent immediate self-reflection.
    float startBias = clamp(thickness * 0.15, 0.03, 0.15);
    vec3 originWS = worldPos + normal * startBias
                              + reflectionDir * 0.04;

    vec3 startVS = (gbufferModelView * vec4(originWS, 1.0)).xyz;
    vec3 dirVS = mat3(gbufferModelView) * reflectionDir;
    vec3 endVS = startVS + dirVS * maxDistance;

    // Clip ONLY against the native near plane. DH extends the FAR plane.
    vec4 nearH = gbufferProjectionInverse * vec4(0.0, 0.0, -1.0, 1.0);
    float nearZ = nearH.z / nearH.w;
    float safeNearZ = nearZ - 0.01;
    if (startVS.z >= safeNearZ)
        return vec4(0.0);

    if (endVS.z >= safeNearZ)
    {
        float denom = endVS.z - startVS.z;
        if (abs(denom) < 1e-7)
            return vec4(0.0);
        float tClip = clamp((safeNearZ - startVS.z) / denom, 0.0, 1.0);
        endVS = mix(startVS, endVS, tClip);
    }

    vec4 clip0 = gbufferProjection * vec4(startVS, 1.0);
    vec4 clip1 = gbufferProjection * vec4(endVS, 1.0);
    if (clip0.w <= 0.0 || clip1.w <= 0.0)
        return vec4(0.0);

    vec2 P0 = (clip0.xy / clip0.w * 0.5 + 0.5) * resolution;
    vec2 P1 = (clip1.xy / clip1.w * 0.5 + 0.5) * resolution;
    vec2 D = P1 - P0;
    if (dot(D, D) < 0.25)
        return vec4(0.0);

    // Starting point must be inside the viewport.
    if (any(lessThan(P0, vec2(0.0))) ||
        any(greaterThanEqual(P0, resolution)))
        return vec4(0.0);

    // Perspective-correct ray view position at screen-space fraction t:
    //   viewPos(t) = mix(Q0, Q1, t) / mix(k0, k1, t)
    float k0 = 1.0 / clip0.w;
    float k1 = 1.0 / clip1.w;
    vec3 Q0 = startVS * k0;
    vec3 Q1 = endVS * k1;

    // Amanatides-Woo DDA in 2D pixel grid, not world-space marching.
    ivec2 cell = ivec2(floor(P0));
    ivec2 stepCell = ivec2(sign(D));

    float tDeltaX = BIG;
    float tDeltaY = BIG;
    float tMaxX   = BIG;
    float tMaxY   = BIG;

    if (abs(D.x) > 1e-7)
    {
        tDeltaX = abs(1.0 / D.x);
        float nextX = floor(P0.x) + (D.x > 0.0 ? 1.0 : 0.0);
        tMaxX = max((nextX - P0.x) / D.x, 0.0);
    }
    if (abs(D.y) > 1e-7)
    {
        tDeltaY = abs(1.0 / D.y);
        float nextY = floor(P0.y) + (D.y > 0.0 ? 1.0 : 0.0);
        tMaxY = max((nextY - P0.y) / D.y, 0.0);
    }

    float tEnter = 0.0;

    for (int i = 0; i < SSR_MAX_STEPS; ++i)
    {
        // Advance to NEXT pixel cell. This skips the origin cell.
        float tBoundary = min(tMaxX, tMaxY);
        if (tBoundary >= 1.0 || tBoundary >= BIG * 0.5)
            break;

        bool stepX = tMaxX <= tMaxY + 1e-7;
        bool stepY = tMaxY <= tMaxX + 1e-7;
        if (stepX)
        {
            cell.x += stepCell.x;
            tMaxX += tDeltaX;
        }
        if (stepY)
        {
            cell.y += stepCell.y;
            tMaxY += tDeltaY;
        }

        tEnter = max(0.0, tBoundary);
        float tExit = min(1.0, min(tMaxX, tMaxY));
        if (tExit <= tEnter)
            continue;

        if (cell.x < 0 || cell.y < 0 ||
            cell.x >= int(viewWidth) || cell.y >= int(viewHeight))
            break;

        vec2 sampleUV = (vec2(cell) + 0.5) / resolution;
        float tMid = 0.5 * (tEnter + tExit);
        float kMid = mix(k0, k1, tMid);
        vec3 rayVS = mix(Q0, Q1, tMid) / max(kMid, 1e-20);

        // The ray itself must be inside the relevant depth projection.
        bool sampleIsDistant = false;
#ifdef DISTANT_HORIZONS
        sampleIsDistant = gfDhFrontAt(sampleUV);
        if (sampleIsDistant)
        {
            vec4 dhClip = dhProjection * vec4(rayVS, 1.0);
            if (dhClip.w <= 0.0 || abs(dhClip.z) > dhClip.w)
                continue;
        }
        else
#endif
        {
            vec4 nativeClip = gbufferProjection * vec4(rayVS, 1.0);
            if (nativeClip.w <= 0.0 || abs(nativeClip.z) > nativeClip.w)
                continue;
        }

        float sceneViewZ;
#ifdef DISTANT_HORIZONS
        if (sampleIsDistant)
        {
            float dhDepth = textureLod(dhDepthTex0, sampleUV, 0.0).r;
            if (dhDepth >= 0.999999)
                continue;
            sceneViewZ = gfDhViewPosition(sampleUV, dhDepth).z;
        }
        else
#endif
        {
            float sceneDepth = texelFetch(depthtex0, cell, 0).r;
            if (sceneDepth >= 0.999999)
                continue; // no geometry: do not reflect background stars

            vec4 sceneH = gbufferProjectionInverse * vec4(
                sampleUV * 2.0 - 1.0, sceneDepth * 2.0 - 1.0, 1.0
            );
            if (abs(sceneH.w) < 1e-20)
                continue;
            sceneViewZ = sceneH.z / sceneH.w;
        }

        // Evaluate the range of ray depths traversed INSIDE THIS pixel.
        // This prevents missing thin geometry when the ray moves a long
        // distance in view space in only one screen-space pixel.
        float zEnter = mix(Q0.z, Q1.z, tEnter) /
            max(mix(k0, k1, tEnter), 1e-20);
        float zExit = mix(Q0.z, Q1.z, tExit) /
            max(mix(k0, k1, tExit), 1e-20);
        float rayNearZ = max(zEnter, zExit);
        float rayFarZ  = min(zEnter, zExit);

        // View-space Z is negative in front of the camera.
        // The scene surface must intersect or be just in front of the ray.
        if (rayFarZ <= sceneViewZ &&
            rayNearZ >= sceneViewZ - thickness)
        {
            // Avoid picking the very same surface that launched the ray.
            if (i < 2)
                continue;
            return vec4(texelFetch(colortex0, cell, 0).rgb, 1.0);
        }
    }

    return vec4(0.0);
}

void main()
{
    // This is a reflection-only target, NOT a copy of the scene color.
    // Background pixels must not leak into the SSR blur.
    finalcolor = vec4(0.0);

    float alpha_g = texture(colortex8, texcoord).g;
    float alpha_r = texture(colortex8, texcoord).r;
    bool isWater = texture(colortex8, texcoord).b > 0.5;

#ifdef DISTANT_HORIZONS
    if (gfDhFrontSky(texcoord)) return;
#else
    if (texture(depthtex0, texcoord).r >= 0.999999) return;
#endif

    if (alpha_g > 0.5 && !isWater) return;
    if (!isWater && alpha_r < 0.1 && wetness < 0.01) return;

    vec3 worldPos = texture(colortex15, texcoord).rgb;
#ifdef DISTANT_HORIZONS
    if (gfDhFrontAt(texcoord))
    {
        float dhDepth = textureLod(dhDepthTex0, texcoord, 0.0).r;
        worldPos = gfDhPlayerPosition(texcoord, dhDepth);
    }
#endif

    vec3 encodedNormal = texture(colortex5, texcoord).rgb;
    if (alpha_r < 0.1 && wetness > 0.01)
        encodedNormal = texture(colortex2, texcoord).rgb;

    vec3 worldNormal = normalize((encodedNormal - 0.5) * 2.0);

#ifdef Realtime_Sky
    vec3 p = worldPos + cameraPosition;
    vec3 worldUp = vec3(0.0, 1.0, 0.0);
    vec3 pcore = normalize(p - gfEarthCenterWorld);
    vec3 tempAxis = cross(worldUp, pcore);
    float theta = acos(clamp(dot(worldUp, pcore), -1.0, 1.0));
    if (dot(tempAxis, tempAxis) > 1e-12)
        worldNormal = rotateVectorAroundAxis(
            worldNormal, normalize(tempAxis), theta);
#endif

    // normalize(worldPos) points FROM CAMERA TOWARD SURFACE.
    // This is the incident direction expected by reflect().
    if (dot(worldPos, worldPos) <= 1e-10) return;
    vec3 incidentDir = normalize(worldPos);
    if (isWater)
    {
        // Two-sided surface normal: face the observer, including underwater.
        if (dot(-incidentDir, worldNormal) < 0.0) worldNormal = -worldNormal;
        worldNormal = grafunWaterNormal(worldNormal, worldPos);
    }
    vec3 reflectDir = normalize(reflect(incidentDir, worldNormal));

    vec4 ssr = grafunSSR2DDDA(worldPos, worldNormal, reflectDir);
    vec3 reflectColor = ssr.rgb;

    if (isWater && ssr.a < 0.5)
    {
        // Screen-space miss: reflect the REAL sky, not black. Keep the
        // 8-step atmospheric reflection separate from direct-view atmosphere.
        vec3 skyBase = skybackground(
            reflectDir, vec2(0.0), 1.0, 0.0
        ).rgb;
        vec3 reflectedOrigin = worldPos + worldNormal * 0.02;
        vec2 atmosphereHit = intersectEarth(reflectDir, reflectedOrigin);
        if (atmosphereHit.y > 0.0)
        {
            vec3 atmosphereStart = reflectedOrigin
                + reflectDir * max(atmosphereHit.x, 0.0);
            vec3 atmosphereEnd = reflectedOrigin
                + reflectDir * atmosphereHit.y;
            reflectColor = Atomfog(
                skyBase, atmosphereStart, atmosphereEnd, 8, 1.0
            );
        }
        else
        {
            reflectColor = skyBase;
        }
        // Compact specular sun/moon glints when SSR cannot hit the disc.
        // No diffuse term. Retain the original 8-step reflected atmosphere.
        float solarGlint = pow(max(dot(reflectDir, normalize(sun_world)), 0.0), 768.0);
        reflectColor += 0.015 * light_color * solarGlint;
        if (sunAngle > 0.5)
        {
            float lunarGlint = pow(max(dot(reflectDir, normalize(-sun_world)), 0.0), 1024.0);
            reflectColor += 0.03 * moon_color * lunarGlint;
        }
    }

    float cosTheta = clamp(dot(-incidentDir, worldNormal), 0.0, 1.0);
    float t = pow(1.0 - cosTheta, 5.0);
    float fresnel = isWater
        ? grafunWaterFresnel(cosTheta)
        : t; // preserve the previous non-water response

    // Premultiplied reflection RGB; alpha stores water's F for compositing.
    finalcolor = vec4(fresnel * reflectColor, isWater ? fresnel : 0.0);
}
