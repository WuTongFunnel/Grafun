const bool colortex1Clear = false;
  //不透明物体延迟渲染
#version 450 compatibility
#define PI 3.1415926535
#include "/lib/function.glsl"
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex14;
uniform vec3 sunPosition;
uniform sampler2D depthtex1;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform int renderStage;
uniform float sunAngle;
uniform vec3 sun_origin_base_color;
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
	const vec3 light_pollution_color=vec3(1,1,1);
	float  light_pollution_k=0;
	if(sun_theta_c<0)light_pollution_k=(1-pow(clamp(sun_theta_s,0,1),84))*0.015*0;
	//阳光直射衰减系数
	float sun_atten_g=0.85,sun_atten_b=0.72;
	float sunlight_k=1;
if(sun_theta_c<0)sunlight_k=clamp(pow(clamp(sun_theta_s,0,1),84),0.001,1);
vec3 sun_base_color=sun_origin_base_color*sunlight_k;
		vec3 sunlightColor = sun_base_color*vec3(1, sun_atten_g*pow(sun_light_theta_c,0.375), sun_atten_b*pow(sun_light_theta_c,0.65));
	 vec3 skylightColor =(sun_base_color-sunlightColor) ;
	 	 skylightColor.g*=0.325;
//散射系数 

	 //天空处理
		if (depth == 1.0) {
			color.rgb=vec3(0,0,0);
		  vec3 sun_view=normalize(sunPosition);
    vec4 NDC_Pos=vec4(texcoord,depth,1)*2-1;
	vec4 view_dir=gbufferProjectionInverse*NDC_Pos;
	view_dir.xyz/=view_dir.w;
	vec3 pixel_view=normalize(view_dir.xyz);
		vec3 pixel_world=mat3(gbufferModelViewInverse)*pixel_view;
		float pixel_world_theta_c=dot(pixel_world, vec3(0,1,0));
			float pixel_world_theta_s=sqrt(clamp(1- pixel_world_theta_c* pixel_world_theta_c,0,1));
vec3 scatter_vector=vec3(1,step(0,pixel_world_theta_c)*sun_atten_g*pow(abs(pixel_world_theta_c),0.375),step(0,pixel_world_theta_c)*sun_atten_b*pow(abs(pixel_world_theta_c),0.65));//0.375,0.65
// 星空渲染
const float fixedYaw   = radians(-90.0);   // 滚动
const float fixedPitch = radians(60.0);   // 上下仰
vec3 sunAxis = rotateVectorAroundAxis(vec3(0,0,1),vec3(1,0,0),radians(-0));

//天空背景渲染

//计算大气折射逆真实向量
float unref_false_theta=asin(pixel_world_theta_c);
vec3  unref_pixel_world=pixel_world;
{
float unref_a=-0.0009375;
float unref_true_theta= unref_false_theta+(unref_a/(unref_false_theta+(unref_a/radians(-0.6))));
vec2 unref_temp=normalize(vec2(pixel_world.x,pixel_world.z));
 unref_pixel_world=normalize(vec3(unref_temp.r,tan(unref_true_theta),unref_temp.g));
}
// 3. 太阳旋转角度（只由时间 sunAngle 驱动，无任何偏移）
float angle = sunAngle * 2*PI;

// 4. 视线星空向量 绕太阳轴旋转（关键：先旋转，再算UV）
vec3 dir = rotateVectorAroundAxis( unref_pixel_world, sunAxis, -angle);
// Yaw
dir = rotateVectorAroundAxis(dir, sunAxis, fixedYaw);
// Pitch
dir = rotateVectorAroundAxis(dir, vec3(1,0,0), fixedPitch);

// 5. 计算最终UV
float lon = atan(dir.z, dir.x);
float lat = acos(-dir.y);
vec2 uv = vec2(lon / (2.0 * PI) + 0.5, lat / PI);
// 6. 采样星空
vec3 starcolor = texture(colortex14, uv).rgb * scatter_vector;
color.rgb = 0.004 * starcolor;

	//太阳渲染
	float unref_pixel_sun_theta_c=dot(unref_pixel_world,sun_world);
	float air_k=1;
	vec3 sun_color=air_k*sun_base_color*scatter_vector+(1-air_k)*sun_base_color;
		if(unref_pixel_sun_theta_c>cos( radians(1.5)))
			{
				
				color.rgb+=(sun_color);
			}
			float pixel_sun_theta_c=dot(pixel_world,sun_world);
			//天空渲染
	vec3 skycolor =(sun_base_color-sun_color);
		float sky_k=1;
if(sun_theta_c<0)sky_k=pow(clamp(pow(sun_theta_s,65),0.001,1),clamp(2+pixel_world_theta_s,0,1))*0.8+0.2; 
				skycolor.rgb *=sky_k;
				skycolor.g*=0.35;
				skycolor*=(1/PI);//修正系数
		color.rgb+=skycolor;
			//体积光照
//阳光米氏散射雾
			float fog_sun_k=pow((pixel_sun_theta_c+1)/(2),5);
			float fog_world_k=0.15+0.85*pow(pixel_world_theta_s,250);
					vec3 fog_color=scatter_vector*sun_base_color;
float remain_E=E(sun_base_color)-E(sun_color)-E(skycolor);
float remain_fog_E_k=0.987*fog_sun_k* fog_world_k;
float fog_E=remain_E*remain_fog_E_k;
float fog_k=fog_E/E(sun_base_color);
float fianlfoglightk=fog_k;
vec3 fog_light_color=fianlfoglightk*fog_color;
					color.rgb+=fog_light_color;

//光污染
color.rgb+=light_pollution_color*scatter_vector*fog_world_k*light_pollution_k;
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
if(sun_theta_c<0)skylight_k=clamp(pow(pow(sun_theta_s,65),2),0.16,1); 
	vec3 skylight=skylightColor*realsky*skylight_k;
	vec3 blocklight = reallight * blocklightColor;
vec3 sunlight = sunlightColor * clamp(dot( sun_world, normal), 0.0, 1.0)*shadow*realsky*step(0.00001, sun_theta_c);

vec3 light_pollution_light=light_pollution_color*light_pollution_k*realsky;
vec3 finallight= skylight+ sunlight+blocklight+ light_pollution_light;
color.rgb*=finallight;
}