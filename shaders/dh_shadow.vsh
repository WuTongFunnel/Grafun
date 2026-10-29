#version 450 compatibility
#define GRAFUN_VERTEX_STAGE
#include "/lib/09_vertex_common.glsl"
#include "/lib/function.glsl"

out vec4 glcolor;
flat out float isWater;

void main()
{
    calculateVertexCommon();

    // Iris DH shaders provide dhMaterialId; mc_Entity is not supported for LODs.
#ifdef DISTANT_HORIZONS
    isWater = (dhMaterialId == DH_BLOCK_WATER) ? 1.0 : 0.0;
#else
    isWater = 0.0;
#endif

    // DH LOD geometry is vertex-colored; it does not use the vanilla block atlas UV.
    glcolor = gl_Color;

    // Match Grafun's native shadow path: unproject to player-relative space,
    // apply the same spherical curvature, then project into the shadow map.
    vec4 p = ftransform();
    p = shadowModelViewInverse * shadowProjectionInverse * p;
    vec4 curvedPosition = spherical_mapping(p);
    gl_Position = shadowProjection * shadowModelView * curvedPosition;

    // Keep the same shadow-map distortion as native Grafun casters.
    gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
}
