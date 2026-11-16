#version 450 compatibility
#include "/lib/function.glsl"

/* RENDERTARGETS: 13 */
layout(location = 0) out vec4 atmosphericScattering;
flat in int gfSkyRefresh;
flat in vec4 gfSkyMetadata;
flat in float gfSkyMoonState;
flat in vec3 gfLutUp;
flat in vec3 gfLutForward;
flat in vec3 gfLutRight;
flat in vec2 gfLutAngles;

// Same H2020 ray mapping as gfSkyViewUVToDirection(), with its
// screen-invariant basis and horizon angles supplied by the vertices.
vec3 gfSkyViewDirectionFromFlatBasis(vec2 uv)
{
    vec2 p = clamp(uv, vec2(0.0), vec2(1.0));
    float zenithAngle;
    if (p.y < 0.5)
    {
        float t = 1.0 - 2.0 * p.y;
        zenithAngle = gfLutAngles.x * (1.0 - t * t);
    }
    else
    {
        float t = 2.0 * p.y - 1.0;
        zenithAngle = gfLutAngles.x + gfLutAngles.y * t * t;
    }
    float cosPhi = 1.0 - 2.0 * p.x * p.x;
    float sinPhi = 2.0 * p.x * sqrt(max(0.0, 1.0 - p.x * p.x));
    return cos(zenithAngle) * gfLutUp
         + sin(zenithAngle) * (cosPhi * gfLutForward + sinPhi * gfLutRight);
}

void main()
{
#ifdef SKY_VIEW_LUT
    ivec2 xy = ivec2(gl_FragCoord.xy);

    bool refresh = gfSkyRefresh != 0;
    float sunAngleNow = gfSkyMetadata.x;
    float horizonNow = gfSkyMetadata.y;
    float heightNow = gfSkyMetadata.z;
    float moonStateNow = gfSkyMoonState;

    if (!refresh)
    {
        // Cheap history copy: do NOT discard. Iris normally flips colortex13
        // after this pass, so discarding would reveal stale alternate data.
        atmosphericScattering = texelFetch(colortex13, xy, 0);
        return;
    }

    vec2 texelUV = (vec2(xy) + 0.5) / vec2(GF_SKYVIEW_SIZE);
    vec2 lutUV = gfSkyViewSubUVToUnit(texelUV);
    vec3 dir = normalize(gfSkyViewDirectionFromFlatBasis(lutUV));

    // Identical original atmosphere() integration (64 steps, black backdrop).
    vec3 scattering = atmosphere(
        vec3(0.0), dir, vec3(0.0),
        1.0, 64
    );

    float metadata = 1.0;
    if (xy.y == 0)
    {
        if      (xy.x == 0) metadata = GF_SKYVIEW_CACHE_SIGNATURE;
        else if (xy.x == 1) metadata = sunAngleNow;
        else if (xy.x == 2) metadata = horizonNow;
        else if (xy.x == 3) metadata = heightNow;
        else if (xy.x == 4) metadata = moonStateNow;
        else if (xy.x == 5) metadata = gfSkyMetadata.w;
    }
    atmosphericScattering = vec4(scattering, metadata);
#else
    atmosphericScattering = vec4(0.0);
#endif
}
