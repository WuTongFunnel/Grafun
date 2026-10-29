#version 450 compatibility
#include "/lib/function.glsl"
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 previousCameraPosition;
uniform mat4 dhPreviousProjection;
in vec2 texcoord;
/* RENDERTARGETS: 0,10*/
layout(location = 0) out vec4 finalColor;
layout(location = 1) out vec4 preColor;
//==============================
// 9 Tap History Sampling
// 静止不用，运动时调用
//==============================
//==============================
// YCoCg
//==============================
vec3 RGBToYCoCg(vec3 c)
{
    return vec3(
        0.25 * c.r +
        0.5  * c.g +
        0.25 * c.b,
        0.5 * c.r -
        0.5 * c.b,
        -0.25 * c.r +
        0.5  * c.g -
        0.25 * c.b
    );
}
vec3 YCoCgToRGB(vec3 c)
{
    float Y  = c.x;
    float Co = c.y;
    float Cg = c.z;
    return vec3(
        Y + Co - Cg,
        Y + Cg,
        Y - Co - Cg
    );
}
vec3 ycocgAABBClampToCenter9(vec2 texcoord, vec3 historyColor)
{
    vec3 cMin = vec3(1e10);
    vec3 cMax = vec3(-1e10);
    ivec2 ipos = ivec2(texcoord * vec2(viewWidth, viewHeight));
    ivec2 res = ivec2(viewWidth, viewHeight);
    for(int x = -1; x <= 1; x++)
    {
        for(int y = -1; y <= 1; y++)
        {
            ivec2 pos = ipos + ivec2(x,y);
            pos = clamp(pos, ivec2(0), res - ivec2(1));
            vec3 rgb = texelFetch(colortex0, pos, 0).rgb;
            vec3 yc = RGBToYCoCg(rgb);
            cMin = min(cMin, yc);
            cMax = max(cMax, yc);
        }
    }
    vec3 pYc = RGBToYCoCg(historyColor);
    vec3 clampedYc = clamp(pYc, cMin, cMax);
    return YCoCgToRGB(clampedYc);
}
//==============================
// Depth
//==============================
float LinearizeDepth(float d)
{
    float z =
        d * 2.0 - 1.0;
    return
        2.0 *
        gbufferProjection[3][2]
        /
        (
        gbufferProjection[2][3] * z
        -
        gbufferProjection[3][3]
        );
}
vec4 findBestHistoryColorRGB(vec2 pretexcoord, vec3 currentColor)
{
    vec2 res = vec2(viewWidth, viewHeight);
    vec2 uvPixel = pretexcoord * res;
    ivec2 basePixel = ivec2(floor(uvPixel));
    float minDiff = 1e10;
    vec4 bestSample = vec4(0.0);
    for(int dx = -1; dx <= 1; dx++)
    {
        for(int dy = -1; dy <= 1; dy++)
        {
            ivec2 px = basePixel + ivec2(dx, dy);
            px = clamp(px, ivec2(0), ivec2(res)-ivec2(1));
            vec4 hist = texelFetch(colortex10, px, 0);
            float diff = length(hist.rgb - currentColor);
            if(diff < minDiff)
            {
                minDiff = diff;
                bestSample = hist;
            }
        }
    }
    return bestSample;
}
vec3 taa(vec3 Color)
{
    float depth = texture(depthtex0, texcoord).r;
    float a = 0.03;
    //==================================================
    // 普通世界 TAA
    //==================================================
    if(depth != 1.0)
    {

        vec3 worldPos =texture(colortex15,texcoord).rgb;
           
        worldPos +=
            cameraPosition -
            previousCameraPosition;
        vec4 prevViewPos =
            gbufferPreviousModelView *
            vec4(worldPos,1.0);
        vec4 prevClip =
            gbufferPreviousProjection *
            prevViewPos;
        if(prevClip.w <= 0.0)
            return Color;
        vec2 prevNDC =
            prevClip.xy /
            prevClip.w;
        if(any(greaterThan(prevNDC,vec2(1.0))) ||
           any(lessThan(prevNDC,vec2(-1.0))))
            return Color;
        vec2 prevtexcoord =
            prevNDC * 0.5 + 0.5;
        //==============================
        // 历史颜色
        // 静止：当前屏幕历史
        // 运动：9tap搜索
        //==============================
        vec4 history =
            texture(
                colortex10,
                texcoord
            );
        vec3 historyColor =
            history.rgb;
        vec2 diff =
            abs(
                (prevtexcoord + djlitter - texcoord)
                *
                vec2(viewWidth,viewHeight)
            );
        if(any(greaterThan(diff,vec2(0.5))))
        {
            history=findBestHistoryColorRGB(prevtexcoord, Color.rgb);
            historyColor =  history.rgb;
               float historyDepth =
            history.a;
        float reprojectDepth =
            prevClip.z /
            prevClip.w;
        reprojectDepth =
            reprojectDepth * 0.5 + 0.5;
        float depthDifference =
            abs(
                reprojectDepth -
                historyDepth
            );
        float threshold = 0.001;
        if(depthDifference > threshold )
        {
            return Color;
        }
        }
          historyColor = ycocgAABBClampToCenter9(texcoord,historyColor);
   
        return mix(
            historyColor,
            Color,
            a
        );
    }
#ifdef DISTANT_HORIZONS
    //==================================================
    // DH TAA
    //==================================================
    float dhdepth =
        texture(dhDepthTex0,texcoord).r;
    if(dhdepth < 1.0)
    {
            vec3 worldPos =texture(colortex15,texcoord).rgb;
        worldPos +=
            cameraPosition -
            previousCameraPosition;
        vec4 prevViewPos =
            gbufferPreviousModelView *
            vec4(worldPos,1.0);
        vec4 prevClip =
            dhPreviousProjection *
            prevViewPos;
        if(prevClip.w <= 0.0)
            return Color;
        vec2 prevNDC =
            prevClip.xy /
            prevClip.w;
        if(any(greaterThan(prevNDC,vec2(1.0))) ||
           any(lessThan(prevNDC,vec2(-1.0))))
            return Color;
        vec2 prevtexcoord =
            prevNDC * 0.5 + 0.5;
        vec4 history =
            texture(
                colortex10,
                texcoord
            );
        vec3 historyColor =
            history.rgb;
        vec2 diff =
            abs(
                (prevtexcoord + djlitter - texcoord)
                *
                vec2(viewWidth,viewHeight)
            );
        if(any(greaterThan(diff,vec2(0.5))))
        {
            history=findBestHistoryColorRGB(prevtexcoord, Color.rgb);
            historyColor =   history.rgb;
        }
                if(history.a<1)
        {
            float depthDifference =
                abs(
                    1.0 -
                    history.a
                );
            float threshold = 0.001;
            if(depthDifference > threshold)
            {
                return Color;
            }
        }
         historyColor = ycocgAABBClampToCenter9(texcoord,historyColor);

        return mix(
            historyColor,
            Color,
            a
        );
    }
#endif
#ifdef Realtime_Sky
    //==================================================
    // Sky TAA
    //==================================================
    if(depth == 1.0)
    {
        vec4 ndc = vec4(
            texcoord * 2.0 - 1.0,
            depth * 2.0 - 1.0,
            1.0
        );
        vec4 viewPos =
            gbufferProjectionInverse *
            ndc;
        viewPos /= viewPos.w;
        vec3 worldPos =
            (gbufferModelViewInverse * viewPos).xyz;
        vec4 prevViewPos =
            gbufferPreviousModelView *
            vec4(worldPos,1.0);
        vec4 prevClip =
            gbufferPreviousProjection *
            prevViewPos;
        if(prevClip.w <= 0.0)
            return Color;
        vec2 prevNDC =
            prevClip.xy /
            prevClip.w;
        if(any(greaterThan(prevNDC,vec2(1.0))) ||
           any(lessThan(prevNDC,vec2(-1.0))))
            return Color;
        vec2 prevtexcoord =
            prevNDC * 0.5 + 0.5;
        vec4 history =
            texture(
                colortex10,
                texcoord
            );
        vec3 historyColor =
            history.rgb;
        vec2 diff =
            abs(
                (prevtexcoord + djlitter - texcoord)
                *
                vec2(viewWidth,viewHeight)
            );
        if(any(greaterThan(diff,vec2(0.5))))
        {
            history=findBestHistoryColorRGB(prevtexcoord, Color.rgb);
            historyColor =
                history.rgb;
        }
              historyColor = ycocgAABBClampToCenter9(texcoord,historyColor);

        return mix(
            historyColor,
            Color,
            a
        );
    }
#endif
    return Color;
}
float LinearToWindowDepth(float linDepth)
{
    float A = gbufferProjection[2][2];
    float B = gbufferProjection[3][2];
    linDepth = max(linDepth, 1e-6);
    float zNdc = B / linDepth - A;
    return zNdc * 0.5 + 0.5;
}
void main()
{
    vec3 fColor = texture(colortex0, texcoord).xyz;
#ifdef TAA
    vec3 taaResult = taa(fColor);
    finalColor = vec4(taaResult, 1.0);
    preColor.rgb = taaResult;
    preColor.a = texture(depthtex0, texcoord).r;
#else
    finalColor = vec4(fColor, 1.0);
    preColor = vec4(0.0);
#endif
}
