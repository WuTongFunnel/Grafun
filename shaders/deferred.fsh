#version 450 compatibility
#include "/lib/function.glsl"
#include "/lib/17_parallel_skylight.glsl"

// The colortex14-sized target is only 128 x 4; no full-resolution
// colortex0 copy or expensive second output attachment is necessary.
// colortex14Format is declared in composite.fsh as a shaderpack directive.
/* RENDERTARGETS: 14 */
layout(location = 0) out vec4 skylightScratch;

void main()
{
    // Preserve the persistent cache. This pass no longer flips or
    // copies the main color buffer; its original color write was a no-op.
    ivec2 xy = ivec2(gl_FragCoord.xy);
    skylightScratch = texelFetch(colortex14, xy, 0);

    // Previously 96 ray integrals were executed serially in six pixels in
    // composite.fsh. Now they are executed by 96 independent fragments.
#ifndef Realtime_Skylight
    if (xy.y == GF_SKYLIGHT_SAMPLE_Y &&
        xy.x >= GF_SKYLIGHT_SAMPLE_X &&
        xy.x < GF_SKYLIGHT_SAMPLE_X + GF_SKYLIGHT_FACE_COUNT * GF_SKYLIGHT_SAMPLES_PER_FACE)
    {
        int index = xy.x - GF_SKYLIGHT_SAMPLE_X;
        int face = index / GF_SKYLIGHT_SAMPLES_PER_FACE;
        uint sampleIndex = uint(index % GF_SKYLIGHT_SAMPLES_PER_FACE);
        vec3 normal = gfSkylightNormal(face);
        vec3 dir = HammersleyCosHemisphereDir(sampleIndex,
            uint(GF_SKYLIGHT_SAMPLES_PER_FACE), normal);
        skylightScratch = vec4(gfEvaluateEnvironmentRadiance(dir), 1.0);
        return;
    }
#endif

#if GF_GROUND_FOG_ENABLED != 0
    // The optional full-sphere cache also runs in parallel when enabled.
    if (xy.y == GF_GENERIC_SAMPLE_Y &&
        xy.x >= GF_GENERIC_SAMPLE_X &&
        xy.x < GF_GENERIC_SAMPLE_X + GF_GENERIC_SAMPLE_COUNT)
    {
        uint i = uint(xy.x - GF_GENERIC_SAMPLE_X);
        vec3 dir = gfGenericSkyUniformSphereDir(i, uint(GF_GENERIC_SAMPLE_COUNT));
        skylightScratch = vec4(gfEvaluateEnvironmentRadiance(dir), 1.0);
    }
#endif
}
