#ifndef GRAFUN_GLOBAL_UNIFORMS_GLSL
#define GRAFUN_GLOBAL_UNIFORMS_GLSL

#include "/lib/setting.glsl"
const float shadowDistance = 512; // [64 128 256 384 512 768 1024]
// defines the total radius in which we sample (in pixels)
#define SHADOW_RADIUS 2// [0.00 0.125 0.25 0.50 0.75 1.00 1.50 2.00 3.00 4.00]
// controls how many samples we take for every pixel we sample
#define SHADOW_RANGE  6 // [1 2 3 4 6]
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D transmittance;
uniform sampler2D multiscattering;
uniform sampler2D ozone;
uniform sampler2D starmaplight;
uniform sampler3D cloudNoiseTex;
uniform sampler2D Earthpicture;
const int shadowMapResolution =4096; // [512 1024 2048 4096 8192]
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const float sunPathRotation=rotation;
const bool shadowcolor0Nearest = true;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 cameraPosition;
uniform int frameCounter; // Iris render-frame index for TAA jitter
uniform float frameTimeCounter; // elapsed render time in seconds (cloud motion)
uniform float rainStrength;
uniform float thunderStrength;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;

#define RGBA32F 0x8814
const int colortex10Format = RGBA32F;
const int colortex13Format = RGBA32F;
// SkyView LUT is history: do not clear either Iris buffer each frame.
const bool colortex13Clear = false;
const bool colortex10Clear = false;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform sampler2D colortex14;
uniform sampler2D colortex15;
uniform int heldBlockLightValue;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D starmap;
uniform sampler2D Moonpicture;
uniform sampler2D MoonHeight;
uniform int worldDay;
uniform float viewHeight;
uniform float viewWidth;
uniform float aspectRatio;
uniform float wetness;
// Mipmap generation must NOT be placed in this shared include.
// The only actual LOD consumers are colortex7 in composite7 (exposure)
// and colortex6 in composite11 (bloom). Keeping the directives local avoids
// generating full texture pyramids before unrelated full-screen passes.
// colortex0 is only ever sampled at base LOD, so it needs no mipmaps.
const bool colortex14Clear = false;
const bool colortex7Clear = false;
uniform sampler2D dhDepthTex1;
#endif // GRAFUN_GLOBAL_UNIFORMS_GLSL
