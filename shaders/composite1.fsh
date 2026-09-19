
  //透明物体延迟渲染
#version 450 compatibility
#include /lib/function.glsl
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex10;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform int renderStage;
uniform float nightVision;
in vec2 texcoord;
/*
const int colortex9Format = RGBA16F;
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

	color.rgb = vec3(color.r,color.g,color.b);
	color.rgb = pow(color.rgb, vec3(2.2));	//shadow
	float depth = texture(depthtex0, texcoord).r;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
vec3 shadow = getSoftShadow(shadowClipPos,depth); 
//light
;
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
    if(sun_theta_c<=0)
{
sunlight_k=pow(clamp(sun_theta_s,0,1),50);
}
vec3 sun_base_color=sun_origin_base_color*sunlight_k;


		float pixel_altitude=max(0.01,(1-(pixel_world.y-62)/(MC_atom_height))*Based_Altitude);
      vec3 scatter_vector=vec3(1);
   float l=1;   
   float sky_altitude=1;
l=(sqrt(MC_ar*MC_ar-pixel_r*pixel_r*sun_theta_s*sun_theta_s)-pixel_r*sun_theta_c)/MC_atom_height;
 float skt=1;
  
    scatter_vector=vec3(pow(sun_atten_r,pow(l,skt)),pow(sun_atten_g,pow(l,skt)),pow(sun_atten_b,pow(l,skt)));
    if(pixel_r>MC_ar)
   {
     scatter_vector=vec3(1);
   }

	vec3 sunlightColor = sun_base_color*scatter_vector;
		vec3 m_color=raw_mie_color(l,sunlightColor);
		sunlightColor -=m_color;
	 vec3 skylightColor =(sun_base_color-sunlightColor) ;
	 	 skylightColor.g*=0.4;
		 skylightColor+=m_color;

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
color.a=1;
      vec3 scatter_vector2=vec3(1);
	  float l2=length(temp_pixel_world_pos);
	  float camera_r=(cameraPosition.y-MC_sealevel)+MC_r;
	  if(camera_r>MC_ar)//平面近似不严谨
	  {
		l2*=((MC_ar-pixel_r)/(camera_r-pixel_r));
		
	  }
	  	  if(pixel_r>MC_ar)//平面近似不严谨
	  {
		l2*=((MC_ar-camera_r)/(pixel_r-camera_r));
		
	  }
	    if(pixel_r>MC_ar&&camera_r>MC_ar)//平面近似不严谨
	  {
		l2=0;
	  }
l2=l2/MC_atom_height;
    scatter_vector2=vec3(pow(sun_atten_r,pow(l2,skt)),pow(sun_atten_g,pow(l2,skt)),pow(sun_atten_b,pow(l2,skt)));
vec3 fogskycolor=vec3(0);
fogskycolor+=fogmodel(l2,sun_base_color,dot(normalize(temp_pixel_world_pos),sun_world));
fogskycolor+=fogmodel(l2,skylight,1);
fogskycolor+=fogmodel(l2,blocklight,1);
fogskycolor+=fogmodel(l2,color.rgb,1);
color.rgb*= scatter_vector2;
 waterfogcolor=vec4(0,0,0,1);
 waterfogcolor.rgb=fogskycolor.rgb;
}