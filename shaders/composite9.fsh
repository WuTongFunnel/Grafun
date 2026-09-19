#version 450 compatibility
uniform sampler2D colortex6;
uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex10;
uniform float viewHeight;
uniform float viewWidth;
in vec2 texcoord;
const bool colortex0MipmapEnabled = true;
/* RENDERTARGETS:0 */
layout(location = 0) out vec4 color;

// spanSearch 函数，放在main外面
vec2 spanSearch(vec2 uvStart, vec2 dir, vec2 baseStep, float lMin, float lMax, sampler2D texColor)
{
    vec2 uvSpan = uvStart;
    vec2 step = baseStep;
    // 粗搜
    for(int i = 0; i < 8; i++)
    {
        step *= 2.0;
        vec2 uvTest = uvSpan + dir * step;
        vec3 sampleCol = texture(texColor, uvTest).rgb;
        float sampleLum = dot(sampleCol, vec3(0.299,0.587,0.114));
        if(sampleLum < lMin || sampleLum > lMax)
        {
            break;
        }
        uvSpan = uvTest;
    }
    // 4次二分回退
    for(int i = 0; i < 4; i++)
    {
        step *= 0.5;
        vec2 uvTest = uvSpan - dir * step;
        vec3 sampleCol = texture(texColor, uvTest).rgb;
        float sampleLum = dot(sampleCol, vec3(0.299,0.587,0.114));
        if(sampleLum >= lMin && sampleLum <= lMax)
        {
            uvSpan = uvTest;
        }
    }
    return uvSpan;
}

void main() {
    color=vec4(0,0,0,1);
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    vec2 pixelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);

    // 5邻域采样颜色
    vec3 cCol = texelFetch(colortex0, pixel, 0).rgb;
    vec3 nCol = texelFetch(colortex0, ivec2(pixel.x, pixel.y+1), 0).rgb;
    vec3 sCol = texelFetch(colortex0, ivec2(pixel.x, pixel.y-1), 0).rgb;
    vec3 eCol = texelFetch(colortex0, ivec2(pixel.x+1, pixel.y), 0).rgb;
    vec3 wCol = texelFetch(colortex0, ivec2(pixel.x-1, pixel.y), 0).rgb;

    // 计算亮度
    float cLum = dot(cCol, vec3(0.299, 0.587, 0.114));
    float nLum = dot(nCol, vec3(0.299, 0.587, 0.114));
    float sLum = dot(sCol, vec3(0.299, 0.587, 0.114));
    float eLum = dot(eCol, vec3(0.299, 0.587, 0.114));
    float wLum = dot(wCol, vec3(0.299, 0.587, 0.114));

    // FXAA梯度构造
    float gradX = abs(nLum - sLum);
    float gradY = abs(eLum - wLum);
    vec2 grad = vec2(gradX, gradY);
    vec2 tangent = vec2(-grad.y, grad.x);
    tangent = normalize(tangent);

    // 局部亮度区间
    float lMax = max(max(max(max(cLum,nLum),sLum),eLum),wLum);
    float lMin = min(min(min(min(cLum,nLum),sLum),eLum),wLum);
    float rangeLum = lMax - lMin;


    // 基础步长
    vec2 baseStep = tangent * pixelSize * 0.5;
    // 双向搜索端点
    vec2 uvA = spanSearch(texcoord, tangent, baseStep, lMin, lMax, colortex0);
    vec2 uvB = spanSearch(texcoord, -tangent, baseStep, lMin, lMax, colortex0);

    // 中点采样 + 固定权重混合
    vec2 uvMid = (uvA + uvB) * 0.5;
    vec3 colCenter = texture(colortex0, texcoord).rgb;
    vec3 colMid = texture(colortex0, uvMid).rgb;
    color.rgb = mix(colCenter, colMid, rangeLum);
}
