#version 450 compatibility
#define GRAFUN_VERTEX_STAGE
#include "/lib/09_vertex_common.glsl"
#include "/lib/function.glsl"
const bool colortex1Clear = false;
out vec2 texcoord;
// Uniform cache decision: evaluated at vertices, flat-fed to 256x128 LUT.
flat out int gfSkyRefresh;
flat out vec4 gfSkyMetadata;
flat out float gfSkyMoonState;
flat out vec3 gfLutUp;
flat out vec3 gfLutForward;
flat out vec3 gfLutRight;
flat out vec2 gfLutAngles;

void main() {
    calculateVertexCommon();
#ifdef SKY_VIEW_LUT
    // Metadata is stored in alpha at the start of the first LUT row.
    // This sampler reads Iris's main texture while the pass writes the alt
    // texture.  Never sample the texture attached for drawing.
    float oldSignature = texelFetch(colortex13, ivec2(0, 0), 0).a;
    float oldSunAngle  = texelFetch(colortex13, ivec2(1, 0), 0).a;
    float oldHorizon   = texelFetch(colortex13, ivec2(2, 0), 0).a;
    float oldHeight    = texelFetch(colortex13, ivec2(3, 0), 0).a;
    float oldMoonState = texelFetch(colortex13, ivec2(4, 0), 0).a;
    float oldBelowSeaLevel = texelFetch(colortex13, ivec2(5, 0), 0).a;

    float belowSeaLevelNow = cameraPosition.y < MC_sealevel ? 1.0 : 0.0;
    vec3 up = normalize(-earth_core_position);
    float sunCosZenith = clamp(dot(normalize(sun_world), up), -1.0, 1.0);
    float sunAngleNow = acos(sunCosZenith);
    float horizonNow, horizonBeta;
    gfSkyViewHorizonAngles(horizonNow, horizonBeta);
    float heightNow = max(gfCameraRadius - MC_r, 0.0);
    float moonStateNow = sunAngle > 0.5 ? 1.0 : 0.0;

    // Tighter sun-angle threshold around dawn/dusk, where scattering changes
    // faster.  Height checks include both geometrical horizon and atmospheric
    // density: the horizon barely changes at high altitude even if density does.
    float sunThreshold = abs(sunCosZenith) < 0.15
        ? GF_SKYVIEW_TWILIGHT_THRESHOLD
        : GF_SKYVIEW_SUN_THRESHOLD;
    float heightThreshold = clamp(0.005 * heightNow, 5.0, 100.0);

    bool refresh =
        frameCounter <= 1 ||
        oldSignature != GF_SKYVIEW_CACHE_SIGNATURE ||
        !(oldSunAngle >= 0.0 && oldSunAngle <= PI) ||
        !(oldHorizon >= 0.0 && oldHorizon <= PI) ||
        !(oldHeight >= 0.0) ||
        oldMoonState != moonStateNow ||
        oldBelowSeaLevel != belowSeaLevelNow ||
        abs(sunAngleNow - oldSunAngle) > sunThreshold ||
        abs(horizonNow - oldHorizon) > GF_SKYVIEW_HORIZON_THRESHOLD ||
        abs(heightNow - oldHeight) > heightThreshold;
    // Used by all LUT texels but independent of their texture coordinates.
    gfSkyViewBasis(gfLutUp, gfLutForward, gfLutRight);
    gfLutAngles = vec2(horizonNow, horizonBeta);
    gfSkyRefresh = refresh ? 1 : 0;
    gfSkyMetadata = vec4(sunAngleNow, horizonNow, heightNow, belowSeaLevelNow);
    gfSkyMoonState = moonStateNow;
#else
    gfSkyRefresh = 1;
    gfSkyMetadata = vec4(0.0);
    gfSkyMoonState = 0.0;
    gfLutUp = vec3(0.0, 1.0, 0.0);
    gfLutForward = vec3(0.0, 0.0, 1.0);
    gfLutRight = vec3(1.0, 0.0, 0.0);
    gfLutAngles = vec2(PI * 0.5);
#endif
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}