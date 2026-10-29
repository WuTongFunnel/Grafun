 //不透明物体延迟渲染
#version 450 compatibility
#include "/lib/function.glsl"
#define PI 3.1415926535
/*
const int colortex14Format = RGBA16F;
*/
/* RENDERTARGETS: 14 */
layout(location = 0) out vec4 skylight;

void main() {
	#ifdef Realtime_Sky
    	skylight=vec4(1);
		#ifndef Realtime_Skylight
		ivec2 uv=ivec2(floor(gl_FragCoord.xy));
			//vec2 uv=gl_FragCoord.xy;
		vec3 normal=vec3(0);
		int tsign=0;
       if(uv.x==0&&uv.y==0)
	   {
		tsign=1;
		normal=vec3(0,1,0);
	   }
	   if(uv.x==0&&uv.y==1)
	   {
		tsign=1;
		normal=vec3(0,-1,0);
	   }
	    if(uv.x==1&&uv.y==0)
	   {
		tsign=1;
		normal=vec3(1,0,0);
	   }
	   if(uv.x==1&&uv.y==1)
	   {
		tsign=1;
		normal=vec3(-1,0,0);
	   }
	    if(uv.x==2&&uv.y==0)
	   {
		tsign=1;
		normal=vec3(0,0,1);
	   }
	   if(uv.x==2&&uv.y==1)
	   {
		tsign=1;
		normal=vec3(0,0,-1);
	   }
	     if(uv.x==3&&uv.y==1)
	   {
		tsign=1;
		   float sunl=sunRayAtmLength(vec3(0), sun_world);  
		  vec3  sunlightColor = light_color*scatterf(sunl/MC_atom_height)*(1-fog_kk(sunl/MC_atom_height,sun_theta_s));
		  skylight.rgb=sunlightColor.rgb;
		  return;
	   }
	       if(uv.x==3&&uv.y==2)
	   {
		tsign=1;
						float moonl=sunRayAtmLength(vec3(0), -sun_world);
				vec3 moonlightcolor=moon_color*scatterf(moonl/MC_atom_height)*(1-fog_kk(moonl/MC_atom_height,sun_theta_s));
		  skylight.rgb=moonlightcolor.rgb;
		  return;
	   }
	   if(tsign==0)
	   {
		return;
	   }
	   		vec3 skylightColor=vec3(0);
	   				uint t=32; 
for(uint i=0;i<t;i++)
{
	vec3 p =HammersleyCosHemisphereDir(i,t,normal);
 vec3 tempcolor= skylightfogmodel(p, vec3(0))+skybackground(p,vec2(0,9),1,1).rgb;

 skylightColor+=tempcolor;
}
skylightColor/=t;
skylightColor *=PI;  
skylight.rgb=skylightColor.rgb;
#endif
#endif
}