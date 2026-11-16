#version 450 compatibility
#include "/lib/function.glsl"
uniform float nightVision;

in vec2 texcoord;
#ifdef Auto_Expousre
const bool colortex7MipmapEnabled = true; // Required for auto-exposure.
#endif
// colortex8 is material metadata, sampled only at the base level.
/* RENDERTARGETS: 14 */
layout(location = 0) out vec4 color;
void main() {
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    color = texelFetch(colortex14, pixel, 0);
#ifdef TAA
    // The final pass writes to the backbuffer only; store the per-frame
    // TAA marker here so the small HDR cache retains its previous behavior.
    if (pixel.x == 5 && pixel.y == 1)
    {
        color = vec4(djlitter, 0.0, 1.0);
        return;
    }
#endif
#ifdef Auto_Expousre
if (pixel.x == 4 && pixel.y == 1)
{
    float pre= texelFetch(colortex14, ivec2(4,1), 0).a;
float maxl =texture2DLod(colortex7, vec2(0.5,0.5), floor(log2(min(viewHeight, viewWidth)))).r;

#if Auto_Expousre_Mode == 1
    float maxt = sunk *999.0*(0.18/0.5);
    float mint = sunk * 1e-9*(0.18/0.5);
#else
    float maxt = sunk * 0.05*(0.18/0.5);
    float mint = sunk * 0.000000625*(0.18/0.5);
#endif

if (nightVision != 0.0)
{
    mint = sunk * 0.0000000375*(0.18/0.5);
}

// 线性亮度上下限转换为 Log2
float maxLog = log2(max(maxt, 1e-20));
float minLog = log2(max(mint, 1e-20));

// maxl 本身已经是平均 Log2 亮度
maxl = clamp(maxl, minLog, maxLog);

// 在 Log2 空间进行时间平滑
#if EXPOSURE_ADAPTATION == 3
    color.a = 0.03 * maxl + 0.97 * pre;
#else
    float adaptation =
        float(EXPOSURE_ADAPTATION) / 100.0;

    color.a = mix(pre, maxl, adaptation);
#endif

}
#endif
}