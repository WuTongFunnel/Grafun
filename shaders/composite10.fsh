#version 450 compatibility
#define GRAFUN_COMPOSITE9
#include "/lib/function.glsl"
in vec2 texcoord;
/* RENDERTARGETS: 0,6*/  
layout(location = 0) out vec4 finalColor;
layout(location = 1) out vec4 bloomcolor;
void main() {
    finalColor = texture(colortex0, texcoord);
    vec4 SunBloomColor = texture(colortex5, texcoord);
float t=gfExposureDivisor;
float Expousre_value=0.18/pow(2,t- Expousre_Gain);
finalColor.rgb*=Expousre_value;
SunBloomColor.rgb*=Expousre_value;


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
finalColor.rgb+=SunBloomColor.rgb;
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