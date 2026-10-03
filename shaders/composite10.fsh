#version 450 compatibility
#include "/lib/function.glsl"
in vec2 texcoord;
/* RENDERTARGETS:0 */
layout(location = 0) out vec4  finalColor;
void main() {
       finalColor = texture(colortex0, texcoord);
   
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    vec4 bloomcolor=vec4(0,0,0,1);
int t=int(min(log2(viewHeight),log2(viewWidth)));
float bloomscatter=Bloom_Scatter;
for(int i=1;i<=t;i++) bloomcolor.rgb+= pow(bloomscatter,i-1)*texture2DLod(colortex6, texcoord, i).rgb;
#ifdef Bloom
finalColor.rgb+=bloomcolor.rgb;
#endif

}