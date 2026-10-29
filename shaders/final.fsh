#version 450 compatibility
#include "/lib/function.glsl"
in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;
// NVIDIA FXAA 3.11
#define FXAA_REDUCE_MIN   (1.0/128.0)
#define FXAA_REDUCE_MUL   (1.0/8.0)
#define FXAA_SPAN_MAX     8.0

vec3 fxaa(vec2 uv)
{
    vec2 pixelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec3 rgbNW = texture2DLod(colortex0, uv + vec2(-1.0,-1.0)*pixelSize,0.0).rgb;
    vec3 rgbNE = texture2DLod(colortex0, uv + vec2( 1.0,-1.0)*pixelSize,0.0).rgb;
    vec3 rgbSW = texture2DLod(colortex0, uv + vec2(-1.0, 1.0)*pixelSize,0.0).rgb;
    vec3 rgbSE = texture2DLod(colortex0, uv + vec2( 1.0, 1.0)*pixelSize,0.0).rgb;
    vec3 rgbM  = texture2DLod(colortex0, uv,0.0).rgb;

    // Rec709 亮度
    vec3 luma = vec3(0.2126, 0.7152, 0.0722);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max( (lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN );
    float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = clamp(dir * rcpDirMin, vec2(-FXAA_SPAN_MAX), vec2(FXAA_SPAN_MAX)) * pixelSize;

    vec3 rgbA = 0.5*(
        texture2DLod(colortex0, uv + dir * (1.0/3.0 - 0.5),0.0).rgb +
        texture2DLod(colortex0, uv + dir * (2.0/3.0 - 0.5),0.0).rgb
    );
    vec3 rgbB = rgbA * 0.5 + 0.25*(
        texture2DLod(colortex0, uv + dir * (0.0/3.0 - 0.5),0.0).rgb +
        texture2DLod(colortex0, uv + dir * (3.0/3.0 - 0.5),0.0).rgb
    );
    float lumaB = dot(rgbB, luma);

    if((lumaB < lumaMin) || (lumaB > lumaMax))
        return rgbA;
    else
        return rgbB;
}

void main() {
color.rgb = fxaa(texcoord);
    color.a = 1.0;
    color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
   // color.rgb = vec3(texture(colortex8, texcoord).r);
}
