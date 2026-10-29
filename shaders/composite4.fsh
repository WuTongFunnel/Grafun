
#version 450 compatibility
#include "/lib/function.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 finalcolor;

void main()
{
    vec3 sceneColor = texture(colortex0, texcoord).rgb;

    vec3 alpha_color = pow(
        texture(colortex3, texcoord).rgb,
        vec3(2.2)
    );

    float depth0 = texture(depthtex0, texcoord).r;
    float depth1 = texture(depthtex1, texcoord).r;

    float camera_r = gfCameraRadius;

    vec3 pixel_world_pos0 =
        texture(colortex15, texcoord).rgb;

    vec4 ndc1 = vec4(
        texcoord * 2.0 - 1.0,
        depth1 * 2.0 - 1.0,
        1.0
    );

    vec4 viewPos1 = gbufferProjectionInverse * ndc1;
    viewPos1 /= viewPos1.w;

    vec3 pixel_world_pos1 =
        (gbufferModelViewInverse * viewPos1).xyz;

    bool frontSky = depth0 >= 0.999999;
    bool backSky = depth1 >= 0.999999;
    bool hasTransparentLayer = depth0 != depth1;

#ifdef DISTANT_HORIZONS

    bool dhFront = gfDhFrontAt(texcoord);
    bool dhOpaque = gfDhOpaqueAt(texcoord);
    bool dhTranslucent = gfDhHasTranslucent(texcoord);

    if (dhFront)
    {
        float dhDepth0 = textureLod(
            dhDepthTex0, texcoord, 0.0
        ).r;

        pixel_world_pos0 =
            gfDhPlayerPosition(texcoord, dhDepth0);
    }

    if (dhOpaque)
    {
        float dhDepth1 = textureLod(
            dhDepthTex1, texcoord, 0.0
        ).r;

        pixel_world_pos1 =
            gfDhPlayerPosition(texcoord, dhDepth1);
    }

    frontSky = gfDhFrontSky(texcoord);
    backSky = gfDhOpaqueSky(texcoord);
    hasTransparentLayer = dhTranslucent;

#endif

   
const int ATMOSPHERE_STEPS = 64;

// 不透明物体的光照
float opaqueLight = pow(
    texture(colortex1, texcoord).g, 2.0
);

// 半透明物体的光照
float translucentLight = pow(
    texture(colortex4, texcoord).g, 2.0
);

// 天空颜色
if (frontSky)
{
    if (length(sceneColor) <= 0.000001)
    {
        sceneColor += sky(
            texcoord, 1.0, camera_r
        ).rgb;
    }
}

vec3 result;

if (hasTransparentLayer && !frontSky)
{
    // 第一段：相机 -> 半透明物体
    // 这一段对应半透明表面，使用 colortex4
    result = atmosphere(
        vec3(0.0),
        pixel_world_pos0,
        sceneColor,
        0.5,
        ATMOSPHERE_STEPS,
        translucentLight
    );

    // 第二段：半透明物体 -> 后方物体或天空
    // 不透明物体用 colortex1，天空用 1.0
    float backLight = backSky ? 1.0 : opaqueLight;

    vec3 backDirection = pixel_world_pos1 - pixel_world_pos0;

    if (backSky)
    {
        backDirection = pixel_world_pos1;

        if (dot(backDirection, backDirection) <= 1e-8)
            backDirection = pixel_world_pos0;
    }

    if (dot(backDirection, backDirection) > 1e-8)
    {
        backDirection = normalize(backDirection);

        vec3 backColor = backSky
            ? sky(texcoord, 1.0, camera_r).rgb
            : sceneColor;

        vec3 backAtmosphere = atmosphere(
            pixel_world_pos0,
            backSky
                ? pixel_world_pos0 + backDirection
                : pixel_world_pos1,
            backColor,
            backSky ? 1.0 : 0.5,
            ATMOSPHERE_STEPS,
            backLight
        );

        result += backAtmosphere * alpha_color;
    }
}
else
{
    // 没有半透明层：直接计算相机到目标的整段
    float light = frontSky ? 1.0 : opaqueLight;

    result = atmosphere(
        vec3(0.0),
        pixel_world_pos0,
        sceneColor,
        frontSky ? 1.0 : 0.5,
        ATMOSPHERE_STEPS,
        light
    );
}

finalcolor = vec4(result, 1.0);

}
