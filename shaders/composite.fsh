 //不透明物体延迟渲染
#version 450 compatibility
#include "/lib/function.glsl"
uniform sampler3D atom;
/*
const int colortex14Format = RGBA16F;
*/
/* RENDERTARGETS: 14 */
layout(location = 0) out vec4 skylight;

void main() {

			ivec2 uv=ivec2(floor(gl_FragCoord.xy));
				skylight=texelFetch(colortex14, uv, 0);
        #ifndef Realtime_Sunlight
        // 1025 optical-depth LUT based solar/lunar attenuation.
        // Cached at (3,1) and (3,2), matching the 1024 layout.
        if (uv.x == 3 && uv.y == 1)
        {
            skylight.rgb = light_color * onlyafterT(vec3(0.0), sun_world);
            return;
        }
        if (uv.x == 3 && uv.y == 2)
        {
            skylight.rgb = moon_color * onlyafterT(vec3(0.0), -sun_world);
            return;
        }
        #endif
		#ifndef Realtime_Skylight
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
	   if(tsign==0)
	   {
		return;
	   }
	   		vec3 skylightColor=vec3(0);
	   				uint t=16u; 
for(uint i=0;i<t;i++)
{
	vec3 p =HammersleyCosHemisphereDir(i,t,normal);
	 vec3  tempcolor=vec3(0);
	 if(p.y<0)
	 {
continue;
	 }
        // 1025 atmospheric model: integrate in the sampled hemisphere direction.
        tempcolor = subAtomfog(vec3(0.0), vec3(0.0), p, 1.0)+skybackground(p,vec2(0,9),1,1).rgb;
 skylightColor+=tempcolor;
}
skylightColor/=float(t);
skylightColor *=PI;  
skylight.rgb=skylightColor.rgb;
#endif
}