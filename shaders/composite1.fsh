const bool colortex1Clear = false;
  //不透明物体延迟渲染
#version 450 compatibility
#define PI 3.1415926535
#include "/lib/function.glsl"
uniform int renderStage;
in vec2 texcoord;

uniform float nightVision;
/*
const int colortex0Format = RGBA16F;
*/
/*
const int colortex5Format = RGBA16F;
*/
/*
const int colortex4Format = RGBA16F;
*/
/*
const int colortex7Format = RGBA16F;
*/
/*
const int colortex13Format = RGBA16F;
*/
/*
const int colortex6Format = RGBA16F;
*/
/*
const int colortex2Format = RGBA16F;
*/
/* RENDERTARGETS: 0*/

layout(location = 0) out vec4 color;
// 仅生成球面单位方向向量，别的啥也不干


void main() {

  	color = texture(colortex0, texcoord);
	color.rgb = pow(color.rgb, vec3(2.2));
		float depth = texture(depthtex1, texcoord).r;
		
	 //天空处理
vec4 NDC_Pos   = vec4(texcoord, depth, 1.0) * 2.0 - 1.0;
vec4 viewPos   = gbufferProjectionInverse * NDC_Pos;
viewPos.xyz   /= viewPos.w;

   
vec3 temp_pixel_world_pos = (gbufferModelViewInverse * viewPos).xyz;
vec3 pixel_world=temp_pixel_world_pos+cameraPosition;

		float pixel_altitude=max(0.01,(1-(pixel_world.y-MC_sealevel)/(MC_atom_height))*Based_Altitude);

   	vec2 light=texture(colortex1, texcoord).rg;
	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
    vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
		vec3 p = pixel_world;
vec3 worldup=vec3(0,1,0);

vec3 mcearthcore=vec3(cameraPosition.x,MC_sealevel-MC_r,cameraPosition.z);
vec3 init_pcore=p-mcearthcore;
float pixel_r=length(init_pcore);
	if(depth==1.0)
	{
if(cameraPosition.y-MC_sealevel>MC_atom_height)
{
	vec3 view_dir=normalize(temp_pixel_world_pos);
	float k=max(dot(view_dir,vec3(0,-1,0)),0);
	float r=cameraPosition.y-MC_sealevel+MC_r;
	float t=MC_ar/r;
	if(t*t+k*k<1)color.rgb=vec3(0);

}

		return;
	}
vec3 pcore=normalize(init_pcore);
vec3 tempaxis = cross(worldup, pcore); 

float theta = acos( clamp(dot(worldup,pcore), -1.0, 1.0) );
vec3 paxis=normalize(tempaxis);
normal=rotateVectorAroundAxis(normal,paxis ,theta);

		float psun_theta_c=dot(pcore,sun_world);
	float psun_theta_s=sqrt(1-pow(psun_theta_c,2));
	float psun_light_theta_c=clamp(psun_theta_c,0.0,1.0);
	//阳光直射衰减系数
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
//散射系数 
//shadow
vec3 shadow=vec3(0);
{
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
vec3 feetPlayerPos = pixel_to_world( depthtex1, texcoord);
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	float pl=length(temp_pixel_world_pos.xz);
shadow= getSoftShadow(shadowClipPos,0.01*((pl)/(7+pl))); 
}
//light
	 


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