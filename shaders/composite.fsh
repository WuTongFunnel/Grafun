// Hemisphere cache reduction, now separated from per-direction tracing.
#version 450 compatibility
#include "/lib/function.glsl"
#include "/lib/17_parallel_skylight.glsl"

/*
const int colortex14Format = RGBA16F;
*/
/* RENDERTARGETS: 14 */
layout(location = 0) out vec4 skylight;

void main()
{
    ivec2 uv = ivec2(gl_FragCoord.xy);
    skylight = texelFetch(colortex14, uv, 0);

    // Directional integration was already computed in parallel by deferred.fsh.
    // Reconstruct exactly the original cosine-weighted hemisphere arithmetic mean.
#ifndef Realtime_Skylight
    int face = -1;
    if      (uv.x == 0 && uv.y == 0) face = 0;
    else if (uv.x == 0 && uv.y == 1) face = 1;
    else if (uv.x == 1 && uv.y == 0) face = 2;
    else if (uv.x == 1 && uv.y == 1) face = 3;
    else if (uv.x == 2 && uv.y == 0) face = 4;
    else if (uv.x == 2 && uv.y == 1) face = 5;
    if (face >= 0)
    {
        vec3 sumRadiance = vec3(0.0);
        int base = GF_SKYLIGHT_SAMPLE_X + face * GF_SKYLIGHT_SAMPLES_PER_FACE;
        for (int i = 0; i < GF_SKYLIGHT_SAMPLES_PER_FACE; ++i)
            sumRadiance += texelFetch(colortex14,
                ivec2(base + i, GF_SKYLIGHT_SAMPLE_Y), 0).rgb;
        skylight.rgb = (PI / float(GF_SKYLIGHT_SAMPLES_PER_FACE)) * sumRadiance;
        return;
    }
#endif

#if GF_GROUND_FOG_ENABLED != 0
    if (uv.x == 3 && uv.y == 0)
    {
        vec3 sumRadiance = vec3(0.0);
        for (int i = 0; i < GF_GENERIC_SAMPLE_COUNT; ++i)
            sumRadiance += texelFetch(colortex14,
                ivec2(GF_GENERIC_SAMPLE_X + i, GF_GENERIC_SAMPLE_Y), 0).rgb;
        skylight = vec4(sumRadiance / float(GF_GENERIC_SAMPLE_COUNT), 1.0);
        return;
    }
#endif

#ifndef Realtime_Sunlight
    if (uv.x == 3 && uv.y == 1)
    {
        skylight.rgb = light_color * onlyafterT(vec3(0.0), sun_world);
        return;
    }
    if (uv.x == 3 && uv.y == 2)
    {
        skylight.rgb = moon_color * onlyafterT(vec3(0.0), -sun_world);
        return;
    }
#endif
}
