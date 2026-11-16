#ifndef GRAFUN_SKYVIEW_SCATTERING_ONLY_GLSL
#define GRAFUN_SKYVIEW_SCATTERING_ONLY_GLSL

// Hillaire 2020 Sky-View LUT parameterization (scattering only).
// X: 0..PI azimuth relative to the projected sun (rotational symmetry).
// Y: quadratic angular mapping on each side of the geometric ground horizon.
//    Half the texels represent directions above the horizon, half below.
// This replaces the old equal-solid-angle (linear cos(zenith)) mapping.
// Atmosphere integration, Earth shading and transmittance are unchanged.
const ivec2 GF_SKYVIEW_SIZE = ivec2(256, 128);

// Deferred1 reads colortex13 (previous frame main) and writes to its alt
// buffer; Iris flips the buffers after the pass.  We store cache metadata in
// the alpha channel of a few LUT texels, leaving all RGB scattering intact.
// Texel (x,0) alpha: 0=signature, 1=solar zenith, 2=horizon zenith,
//                    3=camera altitude, 4=moon integration state.
const float GF_SKYVIEW_CACHE_SIGNATURE = 2026.1114;
const float GF_SKYVIEW_SUN_THRESHOLD = radians(0.10);
const float GF_SKYVIEW_TWILIGHT_THRESHOLD = radians(0.02);
const float GF_SKYVIEW_HORIZON_THRESHOLD = radians(0.02);

// H2020 sub-texel addressing: physical UV=0 and UV=1 correspond exactly
// to the first/last texel centers, and the baker performs the inverse map.
vec2 gfSkyViewUnitToSubUV(vec2 uv)
{
    vec2 size = vec2(GF_SKYVIEW_SIZE);
    return (uv * (size - 1.0) + 0.5) / size;
}

vec2 gfSkyViewSubUVToUnit(vec2 uv)
{
    vec2 size = vec2(GF_SKYVIEW_SIZE);
    return (uv * size - 0.5) / (size - 1.0);
}

void gfSkyViewBasis(out vec3 up, out vec3 forward, out vec3 right)
{
    vec3 radial = -earth_core_position;
    float r = length(radial);
    up = r > 1e-9 ? radial / r : vec3(0.0, 1.0, 0.0);

    // A solar-relative azimuth avoids the 2PI seam and resolves more of the
    // sun / anti-sun gradient.  At the zenith/nadir sun, azimuth is arbitrary;
    // use a stable world tangent reference in that degenerate case.
    forward = sun_world - up * dot(sun_world, up);
    if (dot(forward, forward) < 1e-10)
    {
        forward = vec3(0.0, 0.0, 1.0) - up * up.z;
        if (dot(forward, forward) < 1e-10)
            forward = vec3(1.0, 0.0, 0.0) - up * up.x;
    }
    forward = normalize(forward);
    right = normalize(cross(up, forward));
}

void gfSkyViewHorizonAngles(out float zenithHorizonAngle, out float beta)
{
    // From the observer, the Earth's *solid-surface* tangency separates
    // upper-sky rays from ground-intersecting rays (H2020 construction).
    float r = max(length(earth_core_position), MC_r);
    float tangentDistance = sqrt(max((r - MC_r) * (r + MC_r), 0.0));
    float cosBeta = clamp(tangentDistance / r, 0.0, 1.0);
    beta = acos(cosBeta);
    zenithHorizonAngle = PI - beta;
}

vec3 gfSkyViewUVToDirection(vec2 uv)
{
    vec3 up, forward, right;
    gfSkyViewBasis(up, forward, right);

    float zenithHorizonAngle, beta;
    gfSkyViewHorizonAngles(zenithHorizonAngle, beta);

    vec2 p = clamp(uv, vec2(0.0), vec2(1.0));
    float zenithAngle;
    if (p.y < 0.5)
    {
        float t = 1.0 - 2.0 * p.y;
        zenithAngle = zenithHorizonAngle * (1.0 - t * t);
    }
    else
    {
        float t = 2.0 * p.y - 1.0;
        zenithAngle = zenithHorizonAngle + beta * t * t;
    }

    // H2020: cos(azimuth) = 1 - 2u^2, covering 0..PI relative to the sun.
    // The atmosphere's scattering integrator is azimuthally symmetric about
    // the projected sun; the negative half-plane needs no duplicate texels.
    float cosPhi = 1.0 - 2.0 * p.x * p.x;
    float sinPhi = 2.0 * p.x * sqrt(max(0.0, 1.0 - p.x * p.x));
    return cos(zenithAngle) * up
         + sin(zenithAngle) * (cosPhi * forward + sinPhi * right);
}

// A retained LUT must be sampled using its BAKED horizon angle, not the
// current camera altitude.  The bake side still uses the current atmosphere
// and height; only the lookup gets the saved horizon when the cache is reused.
vec2 gfSkyViewDirectionToUVWithHorizon(
    vec3 direction, float zenithHorizonAngle)
{
    vec3 up, forward, right;
    gfSkyViewBasis(up, forward, right);

    float beta = max(PI - zenithHorizonAngle, 1e-7);

    vec3 dir = normalize(direction);
    float cosTheta = clamp(dot(dir, up), -1.0, 1.0);
    float zenithAngle = acos(cosTheta);
    float v;
    if (zenithAngle < zenithHorizonAngle)
    {
        float t = clamp(zenithAngle / max(zenithHorizonAngle, 1e-7), 0.0, 1.0);
        v = 0.5 * (1.0 - sqrt(max(0.0, 1.0 - t)));
    }
    else
    {
        float t = clamp((zenithAngle - zenithHorizonAngle) / max(beta, 1e-7), 0.0, 1.0);
        v = 0.5 * (1.0 + sqrt(t));
    }

    vec3 horizontal = dir - cosTheta * up;
    float horizontalLen2 = dot(horizontal, horizontal);
    float cosPhi = horizontalLen2 > 1e-12
        ? clamp(dot(horizontal * inversesqrt(horizontalLen2), forward), -1.0, 1.0)
        : 1.0;
    float u = sqrt(max(0.0, 0.5 * (1.0 - cosPhi)));
    return vec2(u, v);
}

// Keep the original API for code paths that want current-height mapping.
vec2 gfSkyViewDirectionToUV(vec3 direction)
{
    float zenithHorizonAngle, beta;
    gfSkyViewHorizonAngles(zenithHorizonAngle, beta);
    return gfSkyViewDirectionToUVWithHorizon(direction, zenithHorizonAngle);
}

#endif
