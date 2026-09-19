#version 450 compatibility
#include "/lib/function.glsl"
uniform sampler2D colortex6;
uniform sampler2D colortex0;
uniform sampler2D colortex10;
uniform sampler2D depthtex0;
uniform float viewHeight;
uniform float viewWidth;
in vec2 texcoord;
/* RENDERTARGETS:0 */
layout(location = 0) out vec4 color;
void main() {
    float m=0.77;
vec2 sampleuv=m*texcoord+0.5-m*0.5;
float l=length(sampleuv-vec2(0.5))*length(sampleuv-vec2(0.5));
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)color.r+=l*texture(colortex11,(1-sampleuv)).r;
 m=0.834;
 l=length(sampleuv-vec2(0.5));
sampleuv=m*texcoord+0.5-m*0.5;
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)color.g+=l*texture(colortex11,(1-sampleuv)).g;
 m=0.91;
 l=length(sampleuv-vec2(0.5));
sampleuv=m*texcoord+0.5-m*0.5;
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)color.b+=l*texture(colortex11,(1-sampleuv)).b;
   vec3 shadow=vec3(0);
{
vec3 feetPlayerPos = vec3(0,0,0);
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
shadow= getSoftShadow(shadowClipPos,100); 
}
if(sunAngle>0.5)shadow=vec3(0);
 float pixel_r=(eyeAltitude-MC_sealevel)+MC_r;
float sunl=skyl(sun_world,pixel_r);
        color.rgb*=0.0375*shadow*scatterf(sunl)*(1.0/18867);
   color.rgb+=texture(colortex0,texcoord).rgb;
   float depth=texture(depthtex0,texcoord).r;
   vec3 pixel_world= screenxyz_to_worldxyz(vec4(texcoord,depth,1));
      float center_depth=texture(depthtex0,vec2(0.5)).r;
   vec3 center_world= screenxyz_to_worldxyz(vec4(vec2(0.5),center_depth,1));

mie_g=0.75;
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*dot(pixel_world,sun_world), 1.5);

   color.rgb+=0.075*shadow*mie_phase*scatterf(sunl) ;
}