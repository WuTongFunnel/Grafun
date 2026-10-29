#version 450 compatibility
#define GRAFUN_VERTEX_STAGE
#define GRAFUN_COMPOSITE9
#include "/lib/09_vertex_common.glsl"
#include "/lib/function.glsl"

out vec2 texcoord;
// colortex6MipmapEnabled is declared in the shared globals include.
void main() {
    calculateVertexCommon();
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}