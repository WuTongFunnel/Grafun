#version 450 compatibility
#include "/lib/function.glsl"
in vec2 texcoord;
/* RENDERTARGETS:5 */
layout(location = 0) out vec4 color;
void main() {
   
   #ifdef Sun_Bloom
    float m=0.11;
vec2 sampleuv=m*texcoord+0.5-m*0.5;
float l=length(sampleuv-vec2(0.5))*length(sampleuv-vec2(0.5));
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)color.r+=l*texture(colortex11,(1-sampleuv)).r;
 m=0.1;
 l=length(sampleuv-vec2(0.5));
sampleuv=m*texcoord+0.5-m*0.5;
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)color.g+=l*texture(colortex11,(1-sampleuv)).g;
 m=0.09;
 l=length(sampleuv-vec2(0.5));
sampleuv=m*texcoord+0.5-m*0.5;
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)color.b+=l*texture(colortex11,(1-sampleuv)).b;
   vec3 shadow=vec3(1);
   
{
vec3 feetPlayerPos = vec3(0,0,0);
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    vec3 shadowNDCPos=shadowClipPos.xyz/shadowClipPos.w;
   bool inShadowFrustum = all(lessThan(abs(shadowNDCPos.xyz), vec3(1.0)));
if(inShadowFrustum){
  shadow= getSoftShadow(shadowClipPos,0.01); 
} 
}

 if(sunAngle>0.5&&pixel_r<MC_ar)shadow=vec3(0);
        color.rgb*=0.075*(1.0/18867);
   float depth=texture(depthtex0,texcoord).r;
   vec3 pixel_world= screenxyz_to_worldxyz(vec4(texcoord,depth,1));
   

mie_g=0.75;
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*dot(pixel_world,sun_world), 1.5);
   vec4 sun_pixel=gbufferProjection*vec4(sun_view, 1.0);
   sun_pixel/= sun_pixel.w;
   vec2 sun_uv = sun_pixel.xy * 0.5 + 0.5;
   float f=1;
      color.rgb+=f*0.075*mie_phase;
vec2 dxy=normalize(texcoord-sun_uv);
vec2 dp=normalize(vec2(0,1));
float tm=0.25;
if(dot(center_world,sun_world)<0)tm=0;
float cosp=pow(abs(dot (dxy,dp)),250);
     color.rgb+=f*tm*0.075*clamp(cosp,0,1)*mie_phase;
     dxy=normalize(texcoord-sun_uv);
 dp=normalize(vec2(1,1));
 cosp=pow(abs(dot (dxy,dp)),250);
     color.rgb+=f*tm*0.075*clamp(cosp,0,1)*mie_phase;
     color.rgb*=shadow*sune;
     #endif
}