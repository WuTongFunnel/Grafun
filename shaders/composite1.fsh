  //透明物体延迟渲染
#version 330 compatibility
#include /lib/distort.glsl
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform int renderStage;
in vec2 texcoord;

/* RENDERTARGETS: 4 */
layout(location = 0) out vec4 color;
void main() {
  	color = texture(colortex3, texcoord);
	color.rgb = vec3(color.r,color.g,color.b);
	color.rgb = pow(color.rgb, vec3(2.2));
	//shadow
	float depth = texture(depthtex0, texcoord).r;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
vec3 shadow1 = getSoftShadow(shadowClipPos); 
  vec3 shadow=shadow1;
//light
	vec2 light=texture(colortex4, texcoord).rg;
	vec3 encodedNormal = texture(colortex5, texcoord).rgb;
    vec3 normal = normalize((encodedNormal - 0.5) * 2.0);

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);
const vec3 sunlightColor = vec3(1,1,0.675);

float sunlight_tensity=4;

float realsky=pow(light.g,2);
float reallight=pow(light.r,2);

	vec3 skylight=skylightColor*realsky*0.4375*sunlight_tensity;
	vec3 blocklight = reallight * blocklightColor*sunlight_tensity;
vec3 lightVector = normalize(sunPosition);
vec3 SunVector = mat3(gbufferModelViewInverse) * lightVector;
float t=0;
if(dot(SunVector,vec3(0,1,0))>0)t=1;
vec3 sunlight = sunlightColor * clamp(dot(SunVector, normal), 0.0, 1.0)*realsky*sunlight_tensity*shadow*t;

color.rgb *=skylight +  sunlight+blocklight;
}