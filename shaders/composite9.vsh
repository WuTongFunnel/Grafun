#version 450 compatibility
#define GRAFUN_VERTEX_STAGE
#define GRAFUN_COMPOSITE8
#define GRAFUN_COMPOSITE9
#include "/lib/09_vertex_common.glsl"
#include "/lib/function.glsl"

out vec2 texcoord;
#ifdef Sun_Bloom
flat out vec3 gfBloomSunTransmittance;
#endif
flat out float gfExposureScale;

void main() {
    calculateVertexCommon();
#ifdef Sun_Bloom
    gfBloomSunTransmittance = onlyafterT(vec3(0.0), sun_world);
#endif
    gfExposureScale = 0.18 / pow(2.0, gfExposureDivisor - Expousre_Gain);
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}