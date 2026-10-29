
  //透明物体延迟渲染
#version 450 compatibility
#include /lib/function.glsl

uniform int renderStage;
uniform float nightVision;
in vec2 texcoord;
/*
const int colortex9Format = RGBA16F;
*/
/*
const int colortex0Format = RGBA16F;
*/
/* RENDERTARGETS: 9,13 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 waterfogcolor;

void main() {
  	color = texture(colortex3, texcoord);
if(color.a<0.1)
{
	discard;
}

	color.rgb = pow(color.rgb, vec3(2.2));	//shadow
	float depth = texture(depthtex0, texcoord).r;
			if(depth==1.0)
	{
		return;
	}
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	float pl=length(feetPlayerPos.xz);
vec3 shadow= getSoftShadow(shadowClipPos,0.04*((pl)/(30+pl))); 
//light

	vec2 light=texture(colortex4, texcoord).rg;
	vec3 encodedNormal = texture(colortex5, texcoord).rgb;
    vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
	vec4 aNDC_Pos   = vec4(texcoord, depth, 1.0) * 2.0 - 1.0;
vec4 aviewPos   = gbufferProjectionInverse * aNDC_Pos;
aviewPos.xyz   /= aviewPos.w;
vec3 temp_pixel_world_pos = (gbufferModelViewInverse * aviewPos).xyz;
vec3 pixel_world=temp_pixel_world_pos+cameraPosition;
		vec3 p = pixel_world;
vec3 worldup=vec3(0,1,0);

vec3 mcearthcore=vec3(cameraPosition.x,MC_sealevel-MC_r,cameraPosition.z);
vec3 init_pcore=p-mcearthcore;
float pixel_r=length(init_pcore);
vec3 pcore=normalize(init_pcore);
vec3 tempaxis = cross(worldup, pcore); 

float theta = acos( clamp(dot(worldup,pcore), -1.0, 1.0) );
vec3 paxis=normalize(tempaxis);
normal=rotateVectorAroundAxis(normal,paxis ,theta);

	vec4 skycolor= texture(colortex10, texcoord);

float sunlight_tensity=1;
			float sun_theta_s=sqrt(1-pow(sun_theta_c,2));
				float sun_light_theta_c=clamp(sun_theta_c,0.0,1.0);
		float sunlight_k=1;
vec3 sun_base_color=sun_origin_base_color*sunlight_k;


		float pixel_altitude=max(0.01,(1-(pixel_world.y-62)/(MC_atom_height))*Based_Altitude);
 		vec3 sunlightColor=light_color ;
vec3 moonlightcolor=vec3(0) ;
			vec3 skylightColor=vec3(0);
			#ifdef Realtime_Sky
			#ifdef Realtime_Skylight
		     {
				uint t=9; 
for(uint i=0;i<t;i++)
{
	vec3 p =HammersleyCosHemisphereDir(i,t,normal);
 vec3 tempcolor= skylightfogmodel(p, temp_pixel_world_pos)+skybackground(p,vec2(0),1,1).rgb;

 skylightColor+=tempcolor;
}
skylightColor/=t;
skylightColor *=PI;  
      }
	  #endif  
#ifndef Realtime_Skylight
{
float x2 = normal.x*normal.x;
float y2 = normal.y*normal.y;
float z2 = normal.z*normal.z;

vec3 Lx = normal.x>0 ? texelFetch(colortex14, ivec2(1,0),0).rgb : texelFetch(colortex14, ivec2(1,1),0).rgb;
vec3 Ly = normal.y>0 ? texelFetch(colortex14, ivec2(0,0),0).rgb : texelFetch(colortex14, ivec2(0,1),0).rgb;
vec3 Lz = normal.z>0 ? texelFetch(colortex14, ivec2(2,0),0).rgb : texelFetch(colortex14, ivec2(2,1),0).rgb;

skylightColor = x2*Lx + y2*Ly + z2*Lz;

}
#endif
#ifdef Realtime_Sunlight
 float sunl=sunRayAtmLength(temp_pixel_world_pos, sun_world);   
				float moonl=sunRayAtmLength(temp_pixel_world_pos, -sun_world);
				moonlightcolor=moon_color*scatterf(moonl/MC_atom_height)*(1-fog_kk(moonl/MC_atom_height,sun_theta_s));
				sunlightColor = light_color*scatterf(sunl/MC_atom_height)*(1-fog_kk(sunl/MC_atom_height,sun_theta_s));
#endif
#ifndef Realtime_Sunlight
sunlightColor=texelFetch(colortex14, ivec2(3,1),0).rgb ;
moonlightcolor=texelFetch(colortex14, ivec2(3,2),0).rgb;
#endif
#endif
float realsky=pow(light.g,2);
float reallight=pow(light.r,2);
reallight=smoothstep(0,1,reallight)*reallight;
if(nightVision!=0)
{
	realsky=1.0;
}
	vec3 skylight=(skylightColor)*realsky;//加上星空光
	vec3 blocklight =reallight * blocklightColor;
vec3 sunlight = sunlightColor * clamp(dot( sun_world, normal), 0.0, 1.0)*shadow;
vec3 moonlight =  moonlightcolor* clamp(dot( -sun_world, normal), 0.0, 1.0)*shadow;
vec3 ambient=realsky*max(dot(normal,vec3(0,-1,0)),0)*(vec3(0.01625)*clamp(dot(sun_world,vec3(0,1,0)),0,1)*(sunlightColor/light_color)+moonk*vec3(0.01625)*clamp(dot(-sun_world,vec3(0,1,0)),0,1));
vec3 finallight=skylight+ blocklight+sunlight+ambient+moonlight;
color.rgb *=(finallight/PI);
}