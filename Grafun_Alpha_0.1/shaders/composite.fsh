const bool colortex1Clear = false;
  //不透明物体延迟渲染
#version 330 compatibility
#include /lib/distort.glsl
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D depthtex1;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform int renderStage;
uniform float sunAngle;
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
  	color = texture(colortex0, texcoord);
	color.rgb = vec3(color.r,color.g,color.b);
	color.rgb = pow(color.rgb, vec3(2.2));
	//shadow
	float depth = texture(depthtex1, texcoord).r;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
vec3 shadow1 = getSoftShadow(shadowClipPos); 
  vec3 shadow=shadow1;
//light
	vec2 light=texture(colortex1, texcoord).rg;
	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
    vec3 normal = normalize((encodedNormal - 0.5) * 2.0);


vec3 lightVector = normalize(sunPosition);
vec3 SunVector = mat3(gbufferModelViewInverse) * lightVector;
float realsky=light.g;
if(realsky>0)realsky=pow(light.g,2);
float reallight=pow(light.r,2);
if(nightVision!=0)
{
	realsky=1.0;
	reallight=1.0;
	shadow=vec3(1.0);
}
const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
float sun_theta=clamp(dot(SunVector, vec3(0,1,0)), 0.0, 1.0);
vec3 sunlightColor = vec3(1,sun_theta,sun_theta);
 vec3 skylightColor = vec3(0.05, 0.15, 0.3);
reallight=smoothstep(0,1,reallight)*reallight;
float sunlight_tensity=4;
	vec3 skylight=skylightColor*realsky*sunlight_tensity*1;
	vec3 blocklight = reallight * blocklightColor*sunlight_tensity;
vec3 sunlight = sunlightColor * clamp(dot(SunVector, normal), 0.0, 1.0)*sunlight_tensity*shadow*realsky;


vec3 finallight=skylight +  sunlight+blocklight;
color.rgb*=finallight;
	if (depth == 1.0) {
		  vec3 sun_vector=normalize(sunPosition);
    vec4 NDC_Pos=vec4(texcoord,texture(depthtex1, texcoord).r,1)*2-1;
	vec4 view_dir=gbufferProjectionInverse*NDC_Pos;
	view_dir.xyz/=view_dir.w;
	vec3 view_vector=normalize(view_dir.xyz);
   color = texture(colortex0, texcoord);
 	color.rgb = pow(color.rgb, vec3(2.2));
	if(dot(view_vector,sun_vector)>0.9997)
	{
		color=vec4(sunlightColor,1);
	}
}
}