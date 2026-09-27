#version 450 compatibility
#include "/lib/function.glsl"
const bool colortex1Clear = false;
out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
void main() {
	vec4 p= gl_Vertex;
vec4 fp=spherical_mapping(p);
 gl_Position = gbufferProjection*gbufferModelView*fp;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
}