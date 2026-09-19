#version 450 compatibility
#include "/lib/function.glsl"
const bool colortex1Clear = false;
out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
/*
const int colortex11Format = RGBA16F;
*/
void main() {
	vec4 p= gl_Vertex;
 gl_Position = gbufferProjection*gbufferModelView*p;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}