#ifndef GRAFUN_VERTEX_COMMON_GLSL
#define GRAFUN_VERTEX_COMMON_GLSL

// Shared values are computed by calculateVertexCommon() in the vertex stage.
// Fragment shaders receive the same values through flat inputs; they do not
// recompute these expressions. This is per vertex / per pass, not once per frame.
#include "/lib/00_globals.glsl"

uniform vec3 sunPosition;
uniform float sunAngle;
uniform vec3 sun_origin_base_color;

// Configuration constants: these never require a varying or a texture cache.
// Planet curvature is kept for the moon and the independent volumetric clouds.
#define earth_factor 1.0
const float ambientOcclusionLevel = 1.0;
const float earth_r = 6371000.0;
const float atom_height = 100000.0;
const float MC_r = earth_r / earth_factor;
const float MC_atom_height = atom_height / earth_factor;
const float MC_ar = MC_r + MC_atom_height;
const float MC_sealevel = 63.0;
const float sunk = 1000.0;
#if BLOCKLIGHT_STRENGTH == 100
const vec3 blocklightColor = sunk * (3.0 / 2600.0) * vec3(BLOCKLIGHT_COLOR_R, BLOCKLIGHT_COLOR_G, BLOCKLIGHT_COLOR_B);
#else
const vec3 blocklightColor = sunk * (3.0 / 2600.0) * vec3(BLOCKLIGHT_COLOR_R, BLOCKLIGHT_COLOR_G, BLOCKLIGHT_COLOR_B) * (float(BLOCKLIGHT_STRENGTH) / 100.0);
#endif

#ifdef GRAFUN_VERTEX_STAGE
    #define GRAFUN_COMMON_IO flat out
#else
    #define GRAFUN_COMMON_IO flat in
#endif

GRAFUN_COMMON_IO vec3 sun_view;
GRAFUN_COMMON_IO vec3 sun_world;
GRAFUN_COMMON_IO vec3 light_color;
GRAFUN_COMMON_IO vec3 sun_see_color;
GRAFUN_COMMON_IO vec3 moon_color;
GRAFUN_COMMON_IO float moon_phase;
GRAFUN_COMMON_IO float moonk;
GRAFUN_COMMON_IO float sun_theta_c;
GRAFUN_COMMON_IO float sun_theta_s;
GRAFUN_COMMON_IO vec3 earth_core_position;
GRAFUN_COMMON_IO float gfCameraRadius;
GRAFUN_COMMON_IO vec3 gfEarthCenterWorld;
GRAFUN_COMMON_IO vec3 gfHandLight;
GRAFUN_COMMON_IO vec2 gfPixelSize;

GRAFUN_COMMON_IO vec3 gfMoonCore;
GRAFUN_COMMON_IO float gfMoonIntersectionC;
GRAFUN_COMMON_IO float gfMoonInside;
GRAFUN_COMMON_IO vec3 gfMoonSunWorld;
GRAFUN_COMMON_IO vec3 gfMoonBasisX;
GRAFUN_COMMON_IO vec3 gfMoonBasisY;
GRAFUN_COMMON_IO vec3 gfMoonBasisZ;
GRAFUN_COMMON_IO mat3 gfStarRotation;

#if defined(GRAFUN_COMPOSITE8) || defined(GRAFUN_COMPOSITE9)
    GRAFUN_COMMON_IO vec3 sune;
#endif

#if defined(GRAFUN_COMPOSITE8) && defined(Sun_Bloom)
    GRAFUN_COMMON_IO vec3 center_world;
    GRAFUN_COMMON_IO vec3 gfCameraShadow;
    GRAFUN_COMMON_IO vec2 gfSunUv;
    GRAFUN_COMMON_IO vec2 gfMoonUv;
#endif

#ifdef GRAFUN_COMPOSITE9
    GRAFUN_COMMON_IO float gfExposureDivisor;
    #ifdef Vignette
        GRAFUN_COMMON_IO vec2 gfVignetteScale;
        #if Vignette_Type == 1
            GRAFUN_COMMON_IO float gfVignetteStep;
            GRAFUN_COMMON_IO float gfVignetteNormalization;
        #endif
    #endif
#endif

#ifdef GRAFUN_COMPOSITE10
    GRAFUN_COMMON_IO int gfBloomMaxLod;
#endif

#undef GRAFUN_COMMON_IO

#ifdef GRAFUN_VERTEX_STAGE

// Existing helpers are defined by function.glsl after this include.
// Keep the original rotation implementation, including its coefficients.
vec3 rotateVectorAroundAxis(vec3 v, vec3 axis, float angle);


#if defined(GRAFUN_COMPOSITE8) && defined(Sun_Bloom)
    vec3 getSoftShadow(vec4 shadowClipPos, float bias);
    vec3 screenxyz_to_worldxyz(vec4 p);
#endif

#if defined(GRAFUN_COMPOSITE9) && defined(Vignette) && Vignette_Type == 1
    float Vignette_integralRect(vec3 fp, float a);
#endif

vec3 calculateVertexStarColumn(vec3 column, vec3 sunAxis, float angle)
{
    column = rotateVectorAroundAxis(column, sunAxis, -angle);
    column = rotateVectorAroundAxis(column, sunAxis, radians(-90.0));
    return rotateVectorAroundAxis(column, vec3(1.0, 0.0, 0.0), radians(60.0));
}

void calculateVertexCommon()
{
    // Sun, moon and camera values: none depend on gl_Vertex or texcoord.
    moon_phase =2.0 * PI * mod(float(worldDay), 27.32166);
    sun_view = normalize(sunPosition);
    sun_world = mat3(gbufferModelViewInverse) * sun_view;
    light_color = sunk * sun_origin_base_color;
#if SUN_BRIGHTNESS != 100
    light_color *= float(SUN_BRIGHTNESS) / 100.0;
#endif
#if SUN_COLOR_R != 100 || SUN_COLOR_G != 100 || SUN_COLOR_B != 100
    light_color *= vec3(SUN_COLOR_R, SUN_COLOR_G, SUN_COLOR_B) / 100.0;
#endif
    #if SUN_SIZE == 100
    sun_see_color = light_color / (2.0 * PI * (1.0 - cos(radians(0.25))));
#else
    sun_see_color = light_color / (2.0 * PI * (1.0 - cos(radians(0.25 * float(SUN_SIZE) / 100.0))));
#endif
    moonk = (1.0 / 40000.0) * (1.0 + cos(moon_phase));
    moon_color = 0.5 * sunk * moonk * sun_origin_base_color;
#if MOONLIGHT_BRIGHTNESS != 100
    moon_color *= float(MOONLIGHT_BRIGHTNESS) / 100.0;
#endif
    sun_theta_c = dot(sun_world, vec3(0.0, 1.0, 0.0));
    sun_theta_s = sqrt(1.0 - pow(sun_theta_c, 2.0));
    earth_core_position = vec3(0.0, MC_sealevel - cameraPosition.y - MC_r, 0.0);
    gfCameraRadius = cameraPosition.y - MC_sealevel + MC_r;
    gfEarthCenterWorld = vec3(cameraPosition.x, MC_sealevel - MC_r, cameraPosition.z);
    gfHandLight = 0.2*heldBlockLightValue * blocklightColor;
    gfPixelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);

    vec3 sunAxis = rotateVectorAroundAxis(vec3(0.0, 0.0, 1.0),
        vec3(1.0, 0.0, 0.0), radians(-rotation));
    float moon_distance = MC_r * 59.0;
#if MOON_DISTANCE != 100
    moon_distance *= float(MOON_DISTANCE) / 100.0;
#endif
    float moon_r = 0.2727 * MC_r;
#if MOON_SIZE != 100
    moon_r *= float(MOON_SIZE) / 100.0;
#endif
    gfMoonCore = (-sun_world * moon_distance)
        - vec3(0.0, cameraPosition.y - MC_sealevel, 0.0);
    gfMoonIntersectionC = dot(gfMoonCore, gfMoonCore) - moon_r * moon_r;
    gfMoonInside = length(gfMoonCore) < moon_r ? 1.0 : 0.0;
    gfMoonSunWorld = rotateVectorAroundAxis(sun_world, sunAxis,moon_phase);
    gfMoonBasisZ = normalize(sun_world);
    gfMoonBasisY = normalize(sunAxis - dot(sunAxis, gfMoonBasisZ) * gfMoonBasisZ);
    gfMoonBasisX = cross(gfMoonBasisY, gfMoonBasisZ);

    // Build columns using the original three transforms, not a replacement
    // rotation formula. The fragment stage only applies the resulting matrix.
    float angle = sunAngle * 2.0 * PI;
    gfStarRotation = mat3(
        calculateVertexStarColumn(vec3(1.0, 0.0, 0.0), sunAxis, angle),
        calculateVertexStarColumn(vec3(0.0, 1.0, 0.0), sunAxis, angle),
        calculateVertexStarColumn(vec3(0.0, 0.0, 1.0), sunAxis, angle)
    );

    #if defined(GRAFUN_COMPOSITE8) || defined(GRAFUN_COMPOSITE9)
    #endif

    #if defined(GRAFUN_COMPOSITE8) && defined(Sun_Bloom)
        // Fixed-coordinate texture reads use the same pass's current textures.
        // The old fragment UV was constant, so these reads use base LOD as well.
        float center_depth = textureLod(depthtex0, vec2(0.5), 0.0).r;
        center_world = screenxyz_to_worldxyz(vec4(vec2(0.5), center_depth, 1.0));
        gfCameraShadow = vec3(1.0);
        vec3 shadowViewPos = (shadowModelView * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
        vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
        vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
        bool inShadowFrustum = all(lessThan(abs(shadowNDCPos), vec3(1.0)));
        if (inShadowFrustum) {
            gfCameraShadow = getSoftShadow(shadowClipPos, 0.01);
        }
        vec4 sun_pixel = gbufferProjection * vec4(sun_view, 1.0);
        sun_pixel /= sun_pixel.w;
        gfSunUv = sun_pixel.xy * 0.5 + 0.5;
        #if MOON_DISTANCE == 100
        vec4 moon_pixel = gbufferProjection * vec4(-sun_view, 1.0);
#else
        vec3 moonViewDirection = mat3(gbufferModelView) * normalize(gfMoonCore);
        vec4 moon_pixel = gbufferProjection * vec4(moonViewDirection, 1.0);
#endif
        moon_pixel /= moon_pixel.w;
        gfMoonUv = moon_pixel.xy * 0.5 + 0.5;
    #endif

    #ifdef GRAFUN_COMPOSITE9
        #ifdef Auto_Expousre
            gfExposureDivisor = texelFetch(colortex14, ivec2(4, 1), 0).a;
        #else
            gfExposureDivisor = MANUAL_EXPOSURE_DIVISOR;
        #endif
        #ifdef Vignette
            float fy = 1.0 / gbufferProjection[1][1];
            float fx = fy * aspectRatio;
            gfVignetteScale = vec2(fx, fy);
            #if Vignette_Type == 1
                gfVignetteStep = fy / viewHeight;
                gfVignetteNormalization = Vignette_integralRect(
                    vec3(0.0, 0.0, 1.0), gfVignetteStep);
            #endif
        #endif
    #endif

    #ifdef GRAFUN_COMPOSITE10
        gfBloomMaxLod = int(log2(min(viewHeight, viewWidth)));
    #endif
}

#endif // GRAFUN_VERTEX_STAGE
#endif // GRAFUN_VERTEX_COMMON_GLSL
