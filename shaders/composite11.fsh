#version 450 compatibility
#define GRAFUN_COMPOSITE10
#include "/lib/function.glsl"
in vec2 texcoord;
#ifdef Bloom
const bool colortex6MipmapEnabled = true; // This pass consumes nonzero Bloom LODs.
#endif
/* RENDERTARGETS:0 */
layout(location = 0) out vec4  finalColor;
void main() {
       finalColor = texture(colortex0, texcoord);
   
#ifdef Bloom
    vec4 bloomcolor = vec4(0.0, 0.0, 0.0, 1.0);
    int t = gfBloomMaxLod;
    float bloomscatter = Bloom_Scatter;
    float scatterWeight = 1.0;
    for (int i = 1; i <= t; ++i)
    {
        // Identical geometric tap weights, but no dynamic pow() per mip level.
        bloomcolor.rgb += scatterWeight * texture2DLod(colortex6, texcoord, i).rgb;
        scatterWeight *= bloomscatter;
    }
#if BLOOM_STRENGTH == 100
finalColor.rgb+=bloomcolor.rgb;
#else
finalColor.rgb+=bloomcolor.rgb * (float(BLOOM_STRENGTH)/100.0);
#endif
#endif

}