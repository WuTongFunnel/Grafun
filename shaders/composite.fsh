const bool colortex1Clear = false;
  //不透明物体延迟渲染
#version 450 compatibility
#define PI 3.1415926535
#include "/lib/function.glsl"
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex1;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
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
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;
void main() {
	const vec3 blocklightColor = 0.5*vec3(1.0, 0.5, 0.08);
  	color = texture(colortex0, texcoord);
	color.rgb = vec3(color.r,color.g,color.b);
	color.rgb = pow(color.rgb, vec3(2.2));
	float depth = texture(depthtex1, texcoord).r;
	//sky
	vec3 lightVector = normalize(sunPosition);
vec3 sun_world = mat3(gbufferModelViewInverse) * lightVector;
	float sun_theta_c=dot (sun_world, vec3(0,1,0));
	float sun_theta_s=sqrt(1-pow(sun_theta_c,2));
	float sun_light_theta_c=clamp(sun_theta_c,0.0,1.0);
	//光污染灯光
	float  light_pollution_k=0;
	if(sun_theta_c<0)light_pollution_k=(1-pow(clamp(sun_theta_s,0,1),84))*0.001*0.75;
	//阳光直射衰减系数
	float sunlight_k=1;
if(sun_theta_c<0)sunlight_k=clamp(pow(clamp(sun_theta_s,0,1),84),0.001,1);
vec3 sun_base_color=sun_origin_base_color*sunlight_k;
		vec3 sunlightColor = sun_base_color*vec3(1,step(0,sun_theta_c)*sun_atten_g*pow(abs(sun_theta_c),0.75),step(0,sun_theta_c)*sun_atten_b*pow(abs(sun_theta_c),1.5));
	 vec3 skylightColor =(sun_base_color-sunlightColor) ;
	 	 skylightColor.g*=0.375;
//散射系数 

	 //天空处理
		if (depth == 1.0) {
			color=sky(texcoord,depth,sun_theta_c);

	return;
}
//shadow
vec3 shadow=vec3(0);
if(sun_theta_c>0)
{
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
vec3 feetPlayerPos = pixel_to_world( depthtex1, texcoord);
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
shadow= getSoftShadow(shadowClipPos); 
}
//light
float reflect_k=1;
	vec2 light=reflect_k*texture(colortex1, texcoord).rg;
	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
    vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
float realsky=pow(light.g,2);
float reallight=pow(light.r,2);
reallight=smoothstep(0,1,reallight)*reallight;
if(nightVision!=0)
{
	realsky=1.0;
	reallight=1.0;
	shadow=vec3(1.0);
}
	float skylight_k=1;
if(sun_theta_c<0)skylight_k=pow(clamp(pow(sun_theta_s,65),0.001,1),2)*0.8+0.2; 
	vec3 skylight=skylightColor*realsky*skylight_k;
	vec3 blocklight =reallight * blocklightColor;
vec3 sunlight = sunlightColor * clamp(dot( sun_world, normal), 0.0, 1.0)*shadow*realsky*step(0.00001, sun_theta_c);

vec3 light_pollution_light=light_pollution_color*light_pollution_k*realsky;
vec3 finallight= skylight+ sunlight+blocklight+ light_pollution_light;
color.rgb*=finallight;
}