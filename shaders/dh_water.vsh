#version 450 compatibility
#define GRAFUN_VERTEX_STAGE
#include "/lib/09_vertex_common.glsl"
#include "/lib/function.glsl"

out vec2 lmcoord;
out vec4 glcolor;
out vec3 normal;
flat out float isWater;

void main()
{
    calculateVertexCommon();
    vec4 playerPos = gl_Vertex;

    playerPos = spherical_mapping(playerPos);
#ifdef DISTANT_HORIZONS
    gl_Position = dhProjection * gbufferModelView * playerPos;
    // Iris automatically declares dhMaterialId; do not redeclare it.
    isWater = dhMaterialId == DH_BLOCK_WATER ? 1.0 : 0.0;
#else
    gl_Position = gbufferProjection * gbufferModelView * playerPos;
    isWater = 1.0;
#endif
 #ifdef TAA
   gl_Position.xy+=(djlitter*gl_Position.w);
   #endif
    // Use the same lightmap remapping as the existing native terrain/water.
    lmcoord = gl_MultiTexCoord2.xy;
    lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
    glcolor = gl_Color;
    normal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
}
