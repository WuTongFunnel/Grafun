const bool colortex1Clear = false;
  //不透明物体延迟渲染
#version 450 compatibility
#define PI 3.1415926535
#include "/lib/function.glsl"
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex10;
const bool colortex0MipmapEnabled = true;
uniform sampler2D depthtex1;
uniform sampler2D depthtex0;
uniform int renderStage;
in vec2 texcoord;

uniform float nightVision;
/*
const int colortex0Format = RGBA16F;
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
/* RENDERTARGETS: 0,10,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 skycolor;
layout(location = 2) out vec4 viewposc;
void main() {
	
  	color = texture(colortex0, texcoord);
	color.rgb = pow(color.rgb, vec3(2.2));
	//sky
		float depth = texture(depthtex1, texcoord).r;
	 //天空处理
	   skycolor=vec4(0.0,0.2,0.3,1);
  skycolor=sky(texcoord,depth);
  		if (depth == 1.0) {
			color=skycolor;
	return;
}
vec4 NDC_Pos   = vec4(texcoord, depth, 1.0) * 2.0 - 1.0;
vec4 viewPos   = gbufferProjectionInverse * NDC_Pos;
viewPos.xyz   /= viewPos.w;

		float depth2 = texture(depthtex0, texcoord).r;
vec4 NDC_Pos2   = vec4(texcoord, depth2, 1.0) * 2.0 - 1.0;
vec4 viewPos2   = gbufferProjectionInverse * NDC_Pos2 ;
viewPos2.xyz   /= viewPos2.w;
viewposc=vec4(viewPos2.xyz,1);
   
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
vec3 pcore=normalize(init_pcore);
vec3 tempaxis = cross(worldup, pcore); 

float theta = acos( clamp(dot(worldup,pcore), -1.0, 1.0) );
vec3 paxis=normalize(tempaxis);
normal=rotateVectorAroundAxis(normal,paxis ,theta);

		float psun_theta_c=dot(pcore,sun_world);
	float psun_theta_s=sqrt(1-pow(psun_theta_c,2));
	float psun_light_theta_c=clamp(psun_theta_c,0.0,1.0);
	//光污染灯光
	float  light_pollution_k=0;
	if(sun_theta_c<0)light_pollution_k=(1-pow(clamp(psun_theta_s,0,1),60))*0.001*0;
	//阳光直射衰减系数
	float sunlight_k=1;
if(psun_theta_c<=0)
{
sunlight_k=pow(clamp(sun_theta_s,0,1),50);
}
vec3 sun_base_color=sun_origin_base_color*sunlight_k;
      vec3 scatter_vector=vec3(1);
   float l=1;   
   float sky_altitude=1;
l=(sqrt(MC_ar*MC_ar-pixel_r*pixel_r*abs(psun_theta_s)*abs(psun_theta_s))-pixel_r*abs(psun_theta_c))/MC_atom_height;
    if(pixel_r>=MC_ar)
   {
    l=0;
   }
   float skt=1;
  
    scatter_vector=vec3(pow(sun_atten_r,pow(l,skt)),pow(sun_atten_g,pow(l,skt)),pow(sun_atten_b,pow(l,skt)));
	
		
		vec3 sunlightColor = sun_base_color*scatter_vector;
		vec3 m_color=raw_mie_color(l,sunlightColor);
		//sunlightColor -=m_color;
	 vec3 skylightColor =(sun_base_color-sunlightColor) ;
	 	 skylightColor.g*=0.4;
		 skylightColor+=m_color;
//散射系数 
//shadow
vec3 shadow=vec3(0);
if(psun_theta_c>0)
{
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
vec3 feetPlayerPos = pixel_to_world( depthtex1, texcoord);
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
shadow= getSoftShadow(shadowClipPos,length(viewPos)); 
}
//light
	 


float realsky=pow(light.g,2);
float reallight=pow(light.r,2);
reallight=smoothstep(0,1,reallight)*reallight;
if(nightVision!=0)
{
	realsky=1.0;
}
	vec3 skylight=(skylightColor+vec3(0.000005))*realsky/2;//加上星空光
	vec3 blocklight =reallight * blocklightColor;
vec3 sunlight = sunlightColor * clamp(dot( sun_world, normal), 0.0, 1.0)*shadow*realsky;

vec3 finallight= skylight+blocklight+sunlight;
color.rgb *=(finallight/PI);
if(texture(depthtex1,texcoord).r-texture(depthtex0,texcoord).r>0)
{
	return;
}
vec3 fogskycolor=vec3(0);
float rm_all_l=length(temp_pixel_world_pos);
float rm_t=128;
float rm_dx=rm_all_l/rm_t;
vec3 rm_v=normalize(temp_pixel_world_pos);
vec3 rm_earth_core_position=vec3(0,MC_sealevel-cameraPosition.y-MC_r,0);
vec3 rm_p=0.5*rm_v*rm_dx;
float rm_use_l=0;
float rm_sky_l=rm_all_l;
for(int i=0;i<rm_t;i++)
{
	if(length(rm_p-rm_earth_core_position)>MC_ar)
	{
		rm_sky_l-=rm_dx;
		rm_p+=rm_v*rm_dx;
		continue;
	}

vec3 rm_shadowViewPos = (shadowModelView * vec4(rm_p, 1.0)).xyz;
	vec4 rm_shadowClipPos = shadowProjection * vec4(rm_shadowViewPos, 1.0);
	   //rm_shadowClipPos.z -= 0.000001; // apply bias
      rm_shadowClipPos.xyz = distortShadowClipPos(rm_shadowClipPos.xyz);
	vec2 rm_shadowtexcoord=0.5+0.5*(rm_shadowClipPos.xy/rm_shadowClipPos.w);
	float rm_p_shadowdepth=0.5+0.5*(rm_shadowClipPos.z/rm_shadowClipPos.w);
float rm_sample_shadowdepth=texture(shadowtex0,rm_shadowtexcoord).r;
if(rm_p_shadowdepth<=rm_sample_shadowdepth)
{
	rm_use_l+=rm_dx;
}
	rm_p+=rm_v*rm_dx;
}
float sun_l=rm_use_l/MC_atom_height;
float sky_l=rm_sky_l/MC_atom_height;
float rm_sun_sign=1;
if(sun_theta_c<0)rm_sun_sign=0;
 float p_r=(eyeAltitude-MC_sealevel)+MC_r;
float sunl=skyl(sun_world,p_r);
fogskycolor+=fogmodel(sun_l,rm_sun_sign*sun_base_color*scatterf(sunl),dot(normalize(temp_pixel_world_pos),sun_world));
fogskycolor+=fogmodel(sky_l,skylight,1);
fogskycolor+=fogmodel(sky_l,blocklight,1);
fogskycolor+=fogmodel(sky_l,color.rgb,1);
vec3 scatter_vector2=scatterf(sky_l);
color.rgb*= scatter_vector2;
color.rgb-=raw_mie_color(sky_l,color.rgb);
color.rgb+=fogskycolor.rgb;
}