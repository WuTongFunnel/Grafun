#version 450 compatibility
#include /lib/function.glsl

out vec2 texcoord;
out vec4 glcolor;
flat out float isWater; 
attribute vec4 mc_Entity;
void main() {
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  glcolor = gl_Color;
gl_Position = ftransform();
  gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
   isWater = mc_Entity.y == 1.0 ? 1.0 : 0.0;
}