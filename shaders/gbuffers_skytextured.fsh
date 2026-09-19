#version 450 compatibility

uniform sampler2D gtexture;
uniform int renderStage;
uniform float alphaTestRef = 0.1;
uniform mat4 gbufferProjectionInverse;
uniform sampler2D depthtex0;
in vec2 texcoord;
in vec4 glcolor;
/*
const int colortex11Format = RGBA16F;
*/
/* RENDERTARGETS: 11 */
layout(location = 0) out vec4 color;

void main() {
	/*if(texcoord.x>0.375&&texcoord.x<0.625&&texcoord.y>0.375&&texcoord.y<0.625)
	{
		color = 18867*texture(gtexture, texcoord) * glcolor;
	color.a=1;
	return;
	}*/
	float r=0.05;
		if(length(texcoord-vec2(0.525,0.525))<0.001)
	{
		discard;
	}
	if(length(texcoord-vec2(0.5,0.5))<r)
	{
		color.rgb=vec3(18867);
	color.a=1;
	return;
	}
	
	discard;
}