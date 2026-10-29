#version 450 compatibility
#define GRAFUN_VERTEX_STAGE
#include "/lib/09_vertex_common.glsl"
#include "/lib/function.glsl"
const bool colortex1Clear = false;
out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
void main() {
    calculateVertexCommon();
#ifdef Realtime_Sky
 	vec4 p=ftransform();
  p=gbufferModelViewInverse*gbufferProjectionInverse*p;
vec4 fp=spherical_mapping(p);
 gl_Position = gbufferProjection*gbufferModelView*fp;
 #endif
  #ifndef Realtime_Sky
  gl_Position=ftransform();
 #endif
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}