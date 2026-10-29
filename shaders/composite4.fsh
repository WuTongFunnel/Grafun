
#version 450 compatibility
#include "/lib/function.glsl"

uniform sampler3D atom;
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 finalcolor;

void main()
{
    vec4 color = texture(colortex0, texcoord);
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

    float fogDepth0 = frontSky ? 1.0 : 0.5;
    float fogDepth1 = backSky ? 1.0 : 0.5;

    vec2 frontLight = texture(
        colortex1, texcoord
    ).rg;

    vec2 transparentLight = texture(
        colortex4, texcoord
    ).rg;

    if (hasTransparentLayer)
        frontLight = transparentLight;

#ifdef Realtime_Sky

    // 前景为空时，加入实时天空
    if (frontSky)
    {
        color.rgb += sky(
            texcoord, 1.0, camera_r
        ).rgb;

        frontLight = vec2(0.0, 1.0);
    }

    // 第一层：相机到前景表面的雾
    vec3 result = fogmodel(
        pixel_world_pos0,
        color.rgb,
        fogDepth0,
        vec3(0.0),
        frontLight
    );

    // 第二层：透明表面后方是天空
    if (hasTransparentLayer && backSky && !frontSky)
    {
        vec3 skyColor = sky(
            texcoord, 1.0, camera_r
        ).rgb;

        vec3 backFog = fogmodel(
            pixel_world_pos1 - pixel_world_pos0,
            skyColor,
            fogDepth1,
            pixel_world_pos0,
            vec2(0.0, 1.0)
        );

        result += backFog * alpha_color;
    }

    finalcolor = vec4(result, 1.0);

#else

    // 非实时天空模式
    vec3 result = color.rgb;

    if (!frontSky)
    {
        result += fogmodel(
            pixel_world_pos0,
            color.rgb,
            fogDepth0,
            vec3(0.0),
            frontLight
        );

        // 后景天空透过透明表面
        if (hasTransparentLayer && backSky)
        {
            if (length(color.rgb) <= 0.000001)
            {
                vec3 direction = normalize(
                    pixel_world_pos1
                );

                float atmosphereLength =
                    sunRayAtmLength(
                        vec3(0.0), direction
                    );

                vec3 atmosphere =
                    moon_color * texture(
                        atom,
                        vec3(lut_texcoord(
                            direction, -sun_world
                        ))
                    ).rgb
                    +
                    light_color * texture(
                        atom,
                        vec3(lut_texcoord(
                            direction, sun_world
                        ))
                    ).rgb
                    +
                    sky(texcoord, 1.0, 0.0).rgb *
                    scatterf(
                        atmosphereLength / atom_height
                    );

                result += atmosphere * alpha_color;
            }
        }
    }
    else
    {
        // 无前景几何体：显示大气天空
        if (length(color.rgb) <= 0.000001)
        {
            vec3 direction = normalize(
                pixel_world_pos0
            );

            float atmosphereLength =
                sunRayAtmLength(
                    vec3(0.0), direction
                );

            vec3 atmosphere =
                moon_color * texture(
                    atom,
                    vec3(lut_texcoord(
                        direction, -sun_world
                    ))
                ).rgb
                +
                light_color * texture(
                    atom,
                    vec3(lut_texcoord(
                        direction, sun_world
                    ))
                ).rgb
                +
                sky(texcoord, 1.0, 0.0).rgb *
                scatterf(
                    atmosphereLength / atom_height
                );

            result += atmosphere;
        }
    }

    finalcolor = vec4(result, 1.0);
float sky=0;
if(frontSky)sky=1;
    finalcolor.rgb= cloud(vec3(0),pixel_world_pos0,finalcolor.rgb,sky);
#endif
}
