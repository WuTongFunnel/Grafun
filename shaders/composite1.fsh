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
/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 color;
layout(location = 2) out vec4 viewposc;
// 仅生成球面单位方向向量，别的啥也不干
vec3 HammersleySphereDir(uint i, uint sampleTotal)
{
    uint bits = i;
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    float rInv = float(bits) * 2.3283064365386963e-10;
    vec2 xi = vec2(float(i)/float(sampleTotal), rInv);
    float u = xi.x;
    float v = xi.y;
    float phi = 2.0 * PI * u;
    float z = 1.0 - 2.0 * v;
    float r = sqrt(max(0.0, 1.0 - z*z));
    return vec3(r * cos(phi), r * sin(phi), z);
}

void main() {

  	color = texture(colortex0, texcoord);
	color.rgb = pow(color.rgb, vec3(2.2));
		float depth = texture(depthtex1, texcoord).r;
			if(depth==1.0)
	{
		color=vec4(0,0,0,1);
		return;
	}
	 //天空处理
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
sunlight_k=pow(clamp(sun_theta_s,0,1),300);
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

		vec3 skylightColor=vec3(0);
		     {
				uint t=8; 
     // 正八面体6个顶点，适合大气raymarch半球采样 / 方向采样
for(uint i=0;i<t;i++)
{
	vec3 p =HammersleySphereDir(i,t);
 vec3 tempcolor= skylightfogmodel(p, temp_pixel_world_pos);
skylightColor+=tempcolor*max(dot(normal, p), 0.0);
}
skylightColor/=t;
skylightColor *= 4.0 * PI;  
      }
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
	vec3 skylight=(skylightColor)*realsky;//加上星空光
	vec3 blocklight =reallight * blocklightColor;
vec3 sunlight = sunlightColor * clamp(dot( sun_world, normal), 0.0, 1.0)*shadow*realsky;
vec3 ambient=vec3(0.01625)*realsky*max(dot(normal,vec3(0,-1,0)),0)*sunlight_k;
vec3 finallight= skylight+blocklight+sunlight+ambient;
color.rgb *=(finallight/PI);

}