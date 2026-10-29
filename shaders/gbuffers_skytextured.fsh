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
/* RENDERTARGETS: 11 */
layout(location = 0) out vec4 color;

void main() {
	float r=0.014445*0.492;
#if SUN_SIZE != 100
    r *= float(SUN_SIZE) / 100.0;
#endif
		if(length(texcoord-vec2(0.5+0.5*r,0.5+0.5*r))<0.02*r)
	{
		discard;
	}
	float l1=length(texcoord-vec2(0.5,0.5));
	if(l1<r)
	{
		color.rgb= sun_see_color;
	color.a=1;
	return;
	}
	float q=1.005*r;
	if(l1<q)
	{
		float k=-1.0/(q-r);
		float b=q/(q-r);
		color.rgb= sun_see_color*(k*l1+b)*0.0001;
	color.a=1;
	return;
	}
	color=vec4(0,0,0,0);
}