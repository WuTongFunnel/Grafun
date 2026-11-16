// Original composite10 logic executed after composite9 TAA in the same fragment.
// colortex6 Bloom seed is written now; composite11 still generates mipmaps and accumulates Bloom.
vec3 gfComputeSunMoonHalo() {
    // This pass writes the sun/moon bloom contributions, not an accumulated input.
    vec3 haloAccum = vec3(0.0);
   
   #ifdef Sun_Bloom
    float m=GHOST_SCALE_R;
vec2 sampleuv=m*texcoord+0.5-m*0.5;
float l=length(sampleuv-vec2(0.5))*length(sampleuv-vec2(0.5));
vec3 suncolor=vec3(0);
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)suncolor.r+=l*texture(colortex11,(1-sampleuv)).r;
 m=GHOST_SCALE_G;
 l=length(sampleuv-vec2(0.5));
sampleuv=m*texcoord+0.5-m*0.5;
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)suncolor.g+=l*texture(colortex11,(1-sampleuv)).g;
 m=GHOST_SCALE_B;
 l=length(sampleuv-vec2(0.5));
sampleuv=m*texcoord+0.5-m*0.5;
if(sampleuv.x>=0&&sampleuv.x<=1&&sampleuv.y>=0&&sampleuv.y<=1)suncolor.b+=l*texture(colortex11,(1-sampleuv)).b;
   vec3 shadow=gfCameraShadow;
float sun_sign=1;
 if(sunAngle>0.5)
 {
   sun_sign=0;
   shadow = vec3(gfSunVisibilityAtCamera);
 }
        suncolor*=sunk*GHOST_INTENSITY*(1.0/sun_see_color);
   vec3 pixel_world= normalize(texture(colortex15,texcoord).rgb);
#ifdef DISTANT_HORIZONS
if (gfDhFrontAt(texcoord)) pixel_world = normalize(gfDhPlayerPosition(texcoord, textureLod(dhDepthTex0, texcoord, 0.0).r));
#endif
   
{
float haloG = HALO_MIE_G;
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - haloG*haloG) / pow(1.0 + haloG*haloG - 2.0*haloG*dot(pixel_world,sun_world), 1.5);
   vec2 sun_uv = gfSunUv;
   float f=1*sunk;
      suncolor.rgb+=f*SUN_HALO_INTENSITY*mie_phase;
vec2 dxy=normalize(texcoord-sun_uv);
vec2 dp=normalize(vec2(0,1));
float tm=SUN_SPIKE_INTENSITY;
if(dot(center_world,sun_world)<0)tm=0;
float cosp=pow(abs(dot (dxy,dp)),SPIKE_SHARPNESS);
     suncolor.rgb+=f*tm*0.075*clamp(cosp,0,1)*mie_phase;
     // Reuse the already-normalized sun-to-pixel direction.
 dp=normalize(vec2(1,1));
 cosp=pow(abs(dot (dxy,dp)),SPIKE_SHARPNESS);
     suncolor.rgb+=f*tm*0.075*clamp(cosp,0,1)*mie_phase;
           vec3 sune = gfBloomSunTransmittance;
     suncolor.rgb*=shadow*sune;

     haloAccum += suncolor.rgb;
}
vec3 moonbloomcolor=vec3(0);
{
float haloG = HALO_MIE_G;
#if MOON_DISTANCE == 100
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - haloG*haloG) / pow(1.0 + haloG*haloG - 2.0*haloG*dot(pixel_world,-sun_world), 1.5);
#else
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - haloG*haloG) / pow(1.0 + haloG*haloG - 2.0*haloG*dot(pixel_world,normalize(gfMoonCore)), 1.5);
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
// Reuse the same moon-to-pixel direction for the diagonal spike.
dp=normalize(vec2(1,1));
cosp=pow(abs(dot (dxy,dp)),SPIKE_SHARPNESS);
moonbloomcolor.rgb+=f*tm*0.075*clamp(cosp,0,1)*mie_phase;
moonbloomcolor.rgb*=shadow*(1-sun_sign);
haloAccum += moonbloomcolor.rgb;
}
     #endif
    return haloAccum;
}

void gfApplyComposite10FromTaa(vec4 taaColor) {
    finalColor = taaColor;
    bloomcolor = vec4(0.0);
    vec3 SunBloomColor = gfComputeSunMoonHalo();
float Expousre_value = gfExposureScale;
finalColor.rgb*=Expousre_value;
SunBloomColor*=Expousre_value;


#ifdef Bloom

 bloomcolor=vec4(0.0,0.0,0.0,1.0);
 if(any(greaterThan(finalColor.rgb, vec3(BLOOM_THRESHOLD))))
{
   bloomcolor.r = max(finalColor.r - BLOOM_THRESHOLD, 0.0);
bloomcolor.g = max(finalColor.g - BLOOM_THRESHOLD, 0.0);
bloomcolor.b = max(finalColor.b - BLOOM_THRESHOLD, 0.0);
bloomcolor.a = 1.0;
}
float depth=texture(depthtex1,texcoord).r;
 #ifdef DISTANT_HORIZONS
if(gfDhOpaqueSky(texcoord))
#else
if(depth==1.0)
#endif
 {
bloomcolor.rgb=vec3(0);
 if(texture(colortex11,texcoord).a>0.5)
 {
   
bloomcolor.rgb=vec3(SUN_BLOOM_BOOST)*sune;
 } 
 } 

#endif
   #ifdef Sun_Bloom
finalColor.rgb+=SunBloomColor;
#endif
#ifdef Vignette 
    float fy=gfVignetteScale.y;
      float fx=gfVignetteScale.x;
      vec3 fp=vec3(0);
       float fk=0;
             fp.y=(texcoord.y-0.5)*fy;
      fp.x=(texcoord.x-0.5)*fx;
      fp.z=1.0;
       #if Vignette_Type==0
fk=Vignette_classic(fp);
#endif
     #if Vignette_Type==1
 float dl=gfVignetteStep;
fk=Vignette_integralRect(fp,dl)/gfVignetteNormalization;
#endif   
#if VIGNETTE_STRENGTH == 100
        finalColor.rgb*=fk;
#elif VIGNETTE_STRENGTH > 0
        finalColor.rgb*=mix(1.0, fk, float(VIGNETTE_STRENGTH)/100.0);
#endif
        
#endif
}
