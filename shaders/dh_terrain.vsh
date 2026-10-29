#version 450 compatibility
#define GRAFUN_VERTEX_STAGE
#include "/lib/09_vertex_common.glsl"
#include "/lib/function.glsl"
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normal;

void main()
{
    calculateVertexCommon();
    // Iris gl_Vertex includes the LOD model offset and is camera-relative.
    // Apply the same Grafun curvature as native terrain, exactly once.


vec4 newViewPos =gbufferModelView*spherical_mapping(gl_Vertex);
    gl_Position = dhProjection * newViewPos;
 #ifdef TAA
   gl_Position.xy+=(djlitter*gl_Position.w);
   #endif
    // DH has no terrain-atlas UV. Color is the LOD albedo; lightmap is already
    // normalized. Retain Grafun's native lightmap remapping for matching light.
    lmcoord = gl_MultiTexCoord2.xy;
    lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
    glcolor = gl_Color;
    normal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
}
