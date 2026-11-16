
#version 450 compatibility
#include "/lib/function.glsl"
#include "/lib/16_ground_fog.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 finalcolor;

// Merge former composite3 into the same per-pixel execution as composite4.
// Exactly the original composition formulas and ordering.
vec3 gfComposeTranslucentBeforeFog(vec4 materialFlags, vec4 color)
{
    if (materialFlags.b > 0.5)
        return color.rgb;

    if (materialFlags.g > 0.5)
    {
        vec3 reflection = texture(colortex9, texcoord).rgb;
        return 0.5 * reflection + 0.48 * color.rgb;
    }
#ifdef DISTANT_HORIZONS
    if (gfDhOpaqueSky(texcoord))
#else
    if (texture(depthtex1, texcoord).r == 1.0)
#endif
        return color.rgb;

    vec3 alphaColor = pow(texture(colortex3, texcoord).rgb, vec3(2.2));
    vec3 reflection = texture(colortex9, texcoord).rgb;
    return alphaColor * color.rgb + reflection * materialFlags.r;
}

void main()
{
    // colortex0 is the pre-composite3 color. Reuse per-pixel results locally.
    vec4 materialFlags = texture(colortex8, texcoord);
    vec3 sceneColor = gfComposeTranslucentBeforeFog(
        materialFlags, texture(colortex0, texcoord));

    float depth0 = texture(depthtex0, texcoord).r;
    float depth1 = texture(depthtex1, texcoord).r;

    float camera_r = gfCameraRadius;

    bool frontSky = depth0 >= 0.999999;
    bool backSky = depth1 >= 0.999999;
    bool hasTransparentLayer = depth0 != depth1;

    // Only groundFog() consumes this intensity. No G-buffer light reads
    // in the default (disabled) ground-fog configuration.
    float opaqueLight = 0.0;
#if GF_GROUND_FOG_ENABLED != 0
    opaqueLight = pow(texture(colortex1, texcoord).g, 2.0);
#endif

#ifdef DISTANT_HORIZONS

    bool dhFront = gfDhFrontAt(texcoord);
    bool dhTranslucent = gfDhHasTranslucent(texcoord);

    frontSky = gfDhFrontSky(texcoord);
    // Rear-sky depth is needed only for translucent rays.
    hasTransparentLayer = dhTranslucent;

#endif

    // The optional ground fog is disabled by default. For a non-sky,
    // non-translucent pixel, groundFog(sceneColor, ...) is an identity,
    // and AIRGLOW also only affects sky. Avoid fetching world position,
    // material ID and reconstructing any ray for these opaque pixels.
#if GF_GROUND_FOG_ENABLED == 0
    if (!frontSky && !hasTransparentLayer)
    {
        finalcolor = vec4(sceneColor, 1.0);
        return;
    }
#endif

    vec3 pixel_world_pos0 = texture(colortex15, texcoord).rgb;
#ifdef DISTANT_HORIZONS
    if (dhFront)
    {
        float dhDepth0 = textureLod(dhDepthTex0, texcoord, 0.0).r;
        pixel_world_pos0 = gfDhPlayerPosition(texcoord, dhDepth0);
    }
#endif

// Do not display or sample the lower-hemisphere sky when the camera is
// below Minecraft sea level. This also bypasses Sky-View LUT sampling.
if (frontSky && gfShouldBlockLowerHemisphereSky(pixel_world_pos0))
{
    finalcolor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
}

const int ATMOSPHERE_STEPS = 64;

// The sky is generated ONLY here (not inside atmosphere()).
// Independently rendered Earth overwrites background stars on a hit.
if (frontSky)
{
    sceneColor += sky(texcoord, 1.0, camera_r).rgb;

    vec4 planet = renderEarth(vec3(0.0), pixel_world_pos0);
    if (planet.a > 0.5)
        sceneColor = planet.rgb;
}

vec3 result;
bool isWater = materialFlags.b > 0.5;

// Shared rear-surface reconstruction only for pixels that actually have a
// translucent foreground. Opaque/sky pixels completely skip the inverse MVP.
if (hasTransparentLayer && !frontSky)
{
    vec4 ndc1 = vec4(
        texcoord * 2.0 - 1.0,
        depth1 * 2.0 - 1.0,
        1.0
    );

    vec4 viewPos1 = gbufferProjectionInverse * ndc1;
    viewPos1 /= viewPos1.w;

    vec3 pixel_world_pos1 =
        (gbufferModelViewInverse * viewPos1).xyz;

#ifdef DISTANT_HORIZONS
    if (gfDhOpaqueAt(texcoord))
    {
        float dhDepth1 = textureLod(dhDepthTex1, texcoord, 0.0).r;
        pixel_world_pos1 = gfDhPlayerPosition(texcoord, dhDepth1);
    }
    backSky = gfDhOpaqueSky(texcoord);
#endif
    if (isWater)
{
    // White, unabsorbing transmission. Do NOT fog two overlapping segments
    // or add the diffuse translucent layer (the old branch double-counted it).
    // A continuous ray through the transparent surface sees the opaque/sky
    // background and receives exactly one fog segment: sky atmosphere for a
    // sky background, or independent ground fog for a non-sky background.
    vec3 rayDirection = pixel_world_pos0;
    if (dot(rayDirection, rayDirection) <= 1e-8)
        rayDirection = pixel_world_pos1;
    if (dot(rayDirection, rayDirection) <= 1e-8)
        rayDirection = vec3(0.0, 1.0, 0.0);
    rayDirection = normalize(rayDirection);

    vec3 backgroundColor = backSky
        ? sky(texcoord, 1.0, camera_r).rgb
        : sceneColor;

    if (backSky)
    {
        // Keep the independently shaded planet in front of distant stars.
        vec4 backPlanet = renderEarth(vec3(0.0), rayDirection);
        if (backPlanet.a > 0.5)
            backgroundColor = backPlanet.rgb;
    }

    if (backSky)
    {
        // Sky remains on the original atmospheric path; local ground fog is
        // never evaluated for a sky background.
        result = atmosphere(
            vec3(0.0),
            rayDirection,
            backgroundColor,
            1.0,
            ATMOSPHERE_STEPS
        );
    }
    else
    {
        result = groundFog(
            backgroundColor,
            vec3(0.0),
            pixel_world_pos1,
            opaqueLight
        );
    }
    }
    else
    {
    // Translucent layer was already blended above, before fog.
    // Keep its known color instead of accumulating into undefined 'result'.
    result = sceneColor;
    // 第一段：相机 -> 前景半透明物体。
    // 非天空路径由独立 groundFog() 处理。


    // 第二段：半透明物体 -> 后方物体或天空
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

        // Behind the translucent layer, independently shade the Earth.
        // Only use the main-pass sky color when the globe is not in the way.
        vec3 backColor = backSky
            ? sky(texcoord, 1.0, camera_r).rgb
            : sceneColor;
        if (backSky)
        {
            vec4 backPlanet = renderEarth(pixel_world_pos0, backDirection);
            if (backPlanet.a > 0.5)
                backColor = backPlanet.rgb;
        }

        vec3 backSegmentColor;
        if (backSky)
        {
            // A sky segment keeps the original atmosphere renderer.
            backSegmentColor = atmosphere(
                pixel_world_pos0,
                pixel_world_pos0 + backDirection,
                backColor,
                1.0,
                ATMOSPHERE_STEPS
            );
        }
        else
        {
            backSegmentColor = groundFog(
                backColor,
                pixel_world_pos0,
                pixel_world_pos1,
                opaqueLight
            );
        }

        // Add only the atmospheric change. Without fog this is exactly zero,
        // so the existing translucent color is not counted twice.
        vec3 alpha_color = pow(texture(colortex3, texcoord).rgb, vec3(2.2));
        result += (backSegmentColor - backColor) * alpha_color;
    }
    }
}
else
{
    // 没有半透明层：直接计算相机到目标的整段

    if (frontSky)
    {
#ifdef SKY_VIEW_LUT
        vec3 rayDirection = normalize(pixel_world_pos0);
        // Metadata was written in this frame's deferred1 pass. Use the
        // horizon angle from the actual baked LUT even if it was reused.
        float bakedHorizon = texelFetch(colortex13, ivec2(2, 0), 0).a;
        vec2 uv = gfSkyViewDirectionToUVWithHorizon(rayDirection, bakedHorizon);
        vec3 skyViewScattering = vec3(0.0);

        // Match H2020 sub-texel coordinates used by the Sky-View baker.
        if (uv.y >= 0.0 && uv.y <= 1.0)
            skyViewScattering = texture(colortex13, gfSkyViewUnitToSubUV(uv)).rgb;

        // If the view hits the solid Earth, attenuate only the camera-to-ground
        // segment; never sample atmospheric transmittance through the planet.
        vec3 backgroundT = onlyafterT(vec3(0.0), rayDirection);
        vec2 groundHit = intersectGround(vec3(0.0), rayDirection);
        if (groundHit.x >= 0.0 && groundHit.y >= 0.0)
        {
            vec3 nearPoint = rayDirection * groundHit.x;
            // Keep the LUT lookup just above the surface to avoid float rounding
            // placing the exact sphere intersection below MC_r.
            // Reverse-ray transmittances isolate the finite camera-ground path.
            vec3 surfaceT = onlyafterT(nearPoint, rayDirection);
            backgroundT = clamp(backgroundT / surfaceT,
                                vec3(0.0), vec3(1.0));
        }

        result = skyViewScattering + sceneColor * backgroundT;
#else
        // Without SkyViewLUT, sky pixels still use the original atmosphere.
        result = atmosphere(
            vec3(0.0),
            pixel_world_pos0,
            sceneColor,
            1.0,
            ATMOSPHERE_STEPS
        );
#endif
    }
    else
    {
        // All non-sky scene segments use the independent ground-fog renderer.
        result = groundFog(
            sceneColor,
            vec3(0.0),
            pixel_world_pos0,
            opaqueLight
        );
    }
}

finalcolor = vec4(result, 1.0);
   // finalcolor.rgb= cloud(vec3(0),pixel_world_pos0,finalcolor.rgb, 1);
#ifdef AIRGLOW
   if(frontSky)
   {
       vec3 airglowColor = airglow(vec3(0.0), normalize(pixel_world_pos0));
       finalcolor.rgb += airglowColor;
   }
#endif
}
