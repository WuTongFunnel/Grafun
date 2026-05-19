#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D shadowcolor0;
uniform float alphaTestRef = 0.1;
uniform int renderStage;
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

in vec3 normal;
/* RENDERTARGETS: 0*/
layout(location = 0) out vec4 color;
void main() {
	color.rgb=vec3(0,0,1);
	color.a=0.045;
}