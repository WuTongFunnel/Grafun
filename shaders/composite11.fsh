#version 450 compatibility
#define GRAFUN_COMPOSITE10
#include "/lib/function.glsl"
in vec2 texcoord;
/* RENDERTARGETS:0 */
layout(location = 0) out vec4  finalColor;
void main() {
       finalColor = texture(colortex0, texcoord);
   
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    vec4 bloomcolor=vec4(0,0,0,1);
int t=gfBloomMaxLod;
float bloomscatter=Bloom_Scatter;
for(int i=1;i<=t;i++) bloomcolor.rgb+= pow(bloomscatter,i-1)*texture2DLod(colortex6, texcoord, i).rgb;
#ifdef Bloom
#if BLOOM_STRENGTH == 100
finalColor.rgb+=bloomcolor.rgb;
#else
finalColor.rgb+=bloomcolor.rgb * (float(BLOOM_STRENGTH)/100.0);
#endif
#endif

}