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
	float r=0.014445*0.492;
		if(length(texcoord-vec2(0.5+0.5*r,0.5+0.5*r))<0.02*r)
	{
		discard;
	}
	float l1=length(texcoord-vec2(0.5,0.5));
	if(l1<r)
	{
		color.rgb=vec3(18867);
	color.a=1;
	return;
	}
	float q=1.005*r;
	if(l1<q)
	{
		float k=-1.0/(q-r);
		float b=q/(q-r);
		color.rgb=vec3(18867)*(k*l1+b)*0.0001;
	color.a=1;
	return;
	}
	color=vec4(0,0,0,0);
}