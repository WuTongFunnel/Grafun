#version 450 compatibility
#include "/lib/function.glsl"
uniform sampler2D gtexture;
uniform int renderStage;
uniform float alphaTestRef = 0.1;
in vec2 texcoord;
in vec4 glcolor;
/*
const int colortex11Format = RGBA16F;
*/


void main() {

discard;
}