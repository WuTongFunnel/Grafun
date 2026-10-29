#version 450 compatibility
#define GRAFUN_COMPOSITE8
#include "/lib/function.glsl"
in vec2 texcoord;
/* RENDERTARGETS:5 */
layout(location = 0) out vec4 color;
void main() {
   
   #ifdef Sun_Bloom
    float m=GHOST_SCALE_R;
vec2 sampleuv=m*texcoord+0.5-m*0.5;
float l=length(sampleuv-vec2(0.5))*length(sampleuv-vec2(0.5));
vec3 suncolor=vec3(0);
#ifdef DISTANT_HORIZONS
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)suncolor.r+=l*texture(colortex11,(1-sampleuv)).r*gfDhSkyVisibility(1-sampleuv);
#else
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)suncolor.r+=l*texture(colortex11,(1-sampleuv)).r;
#endif
 m=GHOST_SCALE_G;
 l=length(sampleuv-vec2(0.5));
sampleuv=m*texcoord+0.5-m*0.5;
#ifdef DISTANT_HORIZONS
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)suncolor.g+=l*texture(colortex11,(1-sampleuv)).g*gfDhSkyVisibility(1-sampleuv);
#else
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)suncolor.g+=l*texture(colortex11,(1-sampleuv)).g;
#endif
 m=GHOST_SCALE_B;
 l=length(sampleuv-vec2(0.5));
sampleuv=m*texcoord+0.5-m*0.5;
#ifdef DISTANT_HORIZONS
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)suncolor.b+=l*texture(colortex11,(1-sampleuv)).b*gfDhSkyVisibility(1-sampleuv);
#else
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)suncolor.b+=l*texture(colortex11,(1-sampleuv)).b;
#endif
   vec3 shadow=gfCameraShadow;
float sun_sign=1;
 if(sunAngle>0.5)sun_sign=0;
        suncolor*=sunk*GHOST_INTENSITY*(1.0/sun_see_color);
   vec3 pixel_world= normalize(texture(colortex15,texcoord).rgb);
#ifdef DISTANT_HORIZONS
if (gfDhFrontAt(texcoord)) pixel_world = normalize(gfDhPlayerPosition(texcoord, textureLod(dhDepthTex0, texcoord, 0.0).r));
#endif
   
{
mie_g=HALO_MIE_G;
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*dot(pixel_world,sun_world), 1.5);
   vec2 sun_uv = gfSunUv;
   float f=1*sunk;
      suncolor.rgb+=f*SUN_HALO_INTENSITY*mie_phase;
vec2 dxy=normalize(texcoord-sun_uv);
vec2 dp=normalize(vec2(0,1));
float tm=SUN_SPIKE_INTENSITY;
if(dot(center_world,sun_world)<0)tm=0;
float cosp=pow(abs(dot (dxy,dp)),SPIKE_SHARPNESS);
     suncolor.rgb+=f*tm*0.075*clamp(cosp,0,1)*mie_phase;
     dxy=normalize(texcoord-sun_uv);
 dp=normalize(vec2(1,1));
 cosp=pow(abs(dot (dxy,dp)),SPIKE_SHARPNESS);
     suncolor.rgb+=f*tm*0.075*clamp(cosp,0,1)*mie_phase;
     suncolor.rgb*=shadow*sune*sun_sign;
#ifdef DISTANT_HORIZONS
suncolor.rgb *= gfDhSkyVisibility(gfSunUv);
#endif
     color.rgb+=suncolor.rgb;
}
vec3 moonbloomcolor=vec3(0);
{
mie_g=HALO_MIE_G;
#if MOON_DISTANCE == 100
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*dot(pixel_world,-sun_world), 1.5);
#else
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*dot(pixel_world,normalize(gfMoonCore)), 1.5);
#endif
vec2 moon_uv = gfMoonUv;
float f=1*moonk*sunk;
moonbloomcolor.rgb+=f*MOON_HALO_INTENSITY*mie_phase;
vec2 dxy=normalize(texcoord-moon_uv);
vec2 dp=normalize(vec2(0,1));
float tm=MOON_SPIKE_INTENSITY;
#if MOON_DISTANCE == 100
if(dot(center_world,-sun_world)<0)tm=0;
#else
if(dot(center_world,normalize(gfMoonCore))<0)tm=0;
#endif
float cosp=pow(abs(dot (dxy,dp)),SPIKE_SHARPNESS);
moonbloomcolor.rgb+=f*tm*0.075*clamp(cosp,0,1)*mie_phase;
dxy=normalize(texcoord-moon_uv);
dp=normalize(vec2(1,1));
cosp=pow(abs(dot (dxy,dp)),SPIKE_SHARPNESS);
moonbloomcolor.rgb+=f*tm*0.075*clamp(cosp,0,1)*mie_phase;
moonbloomcolor.rgb*=shadow*(1-sun_sign);
#ifdef DISTANT_HORIZONS
moonbloomcolor.rgb *= gfDhSkyVisibility(gfMoonUv);
#endif
color.rgb+=moonbloomcolor.rgb;
}
     #endif
}