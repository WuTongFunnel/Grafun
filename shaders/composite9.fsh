#version 450 compatibility
#include "/lib/function.glsl"
in vec2 texcoord;
/* RENDERTARGETS: 0,6*/  
layout(location = 0) out vec4 finalColor;
layout(location = 1) out vec4 bloomcolor;
void main() {
    finalColor = texture(colortex0, texcoord);
    vec4 SunBloomColor = texture(colortex5, texcoord);
float t= 2*texelFetch(colortex7, ivec2(0,0), 0).a;

#ifndef Auto_Expousre
t=0.05;
#endif
finalColor.rgb/=t;
SunBloomColor.rgb/=t;
finalColor.rgb*=Expousre_Gain;
SunBloomColor.rgb*=Expousre_Gain;


#ifdef Bloom

 bloomcolor=vec4(0.0,0.0,0.0,1.0);
 if(any(greaterThan(finalColor.rgb, vec3(1.0))))
{
   bloomcolor.r = max(finalColor.r - 1.0, 0.0);
bloomcolor.g = max(finalColor.g - 1.0, 0.0);
bloomcolor.b = max(finalColor.b - 1.0, 0.0);
bloomcolor.a = 1.0;
}
float depth=texture(depthtex1,texcoord).r;
 if(depth==1.0)
 {
bloomcolor.rgb=vec3(0);
 if(texture(colortex11,texcoord).a>0.5)
 {
   
bloomcolor.rgb=vec3(25)*sune;
 } 
 } 

#endif
   #ifdef Sun_Bloom
finalColor.rgb+=SunBloomColor.rgb;
#endif
#ifdef Vignette 
 float tanhalffov=1/gbufferProjection[1][1];
    float fy=tanhalffov;
      float fx=tanhalffov*aspectRatio;
      vec3 fp=vec3(0);
       float fk=0;
             fp.y=(texcoord.y-0.5)*fy;
      fp.x=(texcoord.x-0.5)*fx;
      fp.z=1.0;
       #if Vignette_Type==0
fk=Vignette_classic(fp);
#endif
     #if Vignette_Type==1
 float dl=fy/viewHeight;
fk=Vignette_integralRect(fp,dl)/Vignette_integralRect(vec3(0,0,1),dl);
#endif   
        finalColor.rgb*=fk;
        
#endif
}