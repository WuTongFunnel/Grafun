#ifndef GRAFUN_PARALLEL_SKYLIGHT_GLSL
#define GRAFUN_PARALLEL_SKYLIGHT_GLSL

// Cache scratch positions in colortex14. Keep out of the (0..5, 0..2)
// persistent small cache rectangle (sun/moon/exposure/TAA).
#define GF_SKYLIGHT_SAMPLE_X 16
#define GF_SKYLIGHT_SAMPLE_Y 1
#define GF_SKYLIGHT_SAMPLES_PER_FACE 16
#define GF_SKYLIGHT_FACE_COUNT 6
#define GF_GENERIC_SAMPLE_X 16
#define GF_GENERIC_SAMPLE_Y 0
#define GF_GENERIC_SAMPLE_COUNT 32

vec3 gfSkylightNormal(int face)
{
    if (face == 0) return vec3(0.0, 1.0, 0.0);
    if (face == 1) return vec3(0.0, -1.0, 0.0);
    if (face == 2) return vec3(1.0, 0.0, 0.0);
    if (face == 3) return vec3(-1.0, 0.0, 0.0);
    if (face == 4) return vec3(0.0, 0.0, 1.0);
    return vec3(0.0, 0.0, -1.0);
}

#if GF_GROUND_FOG_ENABLED != 0
vec3 gfGenericSkyUniformSphereDir(uint i, uint sampleTotal)
{
    float u = (float(i) + 0.5) / float(sampleTotal);
    float v = float(bitfieldReverse(i)) * 2.3283064365386963e-10;
    float y = 1.0 - 2.0 * u;
    float radius = sqrt(max(0.0, 1.0 - y * y));
    float phi = 2.0 * PI * v;
    return vec3(radius * cos(phi), y, radius * sin(phi));
}
#endif

vec3 gfEvaluateEnvironmentRadiance(vec3 direction)
{
    vec3 rayOrigin = vec3(0.0);
    vec3 rayDir = normalize(direction);

    if (gfShouldBlockLowerHemisphereSky(rayDir))
        return vec3(0.0);

    vec4 earthSample = renderEarth(rayOrigin, rayDir);
    vec3 backgroundRadiance = earthSample.a > 0.5
        ? earthSample.rgb
        : skybackground(rayDir, vec2(0.0, 9.0), 1.0, 1.0).rgb;
    return atmosphere(rayOrigin, rayDir, backgroundRadiance, 1.0, 64);
}

#endif
