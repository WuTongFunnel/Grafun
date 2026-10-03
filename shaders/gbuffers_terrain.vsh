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
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
	glcolor = gl_Color;
	normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space
}