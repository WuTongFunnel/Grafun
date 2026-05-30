
  //透明物体延迟渲染
#version 450 compatibility
#include /lib/function.glsl
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform int renderStage;
uniform float nightVision;
in vec2 texcoord;
/*
const int colortex9Format = RGBA16F;
*/
/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 color;
void main() {
  	color = texture(colortex3, texcoord);
	color.rgb = vec3(color.r,color.g,color.b);
	color.rgb = pow(color.rgb, vec3(2.2));	//shadow
	float depth = texture(depthtex0, texcoord).r;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
vec3 shadow1 = getSoftShadow(shadowClipPos); 
  vec3 shadow=shadow1;
//light
vec3 lightVector = normalize(sunPosition);
vec3 sun_world = mat3(gbufferModelViewInverse) * lightVector;
	vec2 light=texture(colortex4, texcoord).rg;
	vec3 encodedNormal = texture(colortex5, texcoord).rgb;
    vec3 normal = normalize((encodedNormal - 0.5) * 2.0);

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);



float sunlight_tensity=1;

		float sun_theta_c=dot (sun_world, vec3(0,1,0));
			float sun_theta_s=sqrt(1-pow(sun_theta_c,2));
				float sun_light_theta_c=clamp(sun_theta_c,0.0,1.0);
	float sun_atten_g=0.85,sun_atten_b=0.72;
		float sunlight_k=1;
if(sun_theta_c<0)sunlight_k=clamp(pow(clamp(sun_theta_s,0,1),84),0.001,1);
vec3 sun_base_color=sun_origin_base_color*sunlight_k;
		vec3 sunlightColor = sun_base_color*vec3(1,step(0,sun_theta_c)*sun_atten_g*pow(abs(sun_theta_c),0.75),step(0,sun_theta_c)*sun_atten_b*pow(abs(sun_theta_c),1.5));
	 vec3 skylightColor =(sun_base_color-sunlightColor) ;
	 	 skylightColor.g*=0.375;

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
	vec3 blocklight = 0.5*reallight * blocklightColor*sunlight_tensity;
vec3 sunlight = realsky*sunlightColor * abs(dot(sun_world, normal))*shadow;

vec3 finallight= skylight+ sunlight+blocklight;
color.rgb *=(finallight);
color.a=1;
}