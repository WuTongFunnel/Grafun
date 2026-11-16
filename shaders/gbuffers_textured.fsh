
#version 450 compatibility
const bool colortex1Clear = false;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D colortex1;
uniform int renderStage;
// No colortex0 MIP level is used; avoid misleading pack directives.
// colortex14 is accessed by texelFetch at LOD 0: no mipmap required.
uniform float alphaTestRef = 0.1;
/*
const int colortex10Format = RGBA16F;
*/
/*
const int colortex12Format = RGBA16F;
*/
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

in vec3 normal;

/* RENDERTARGETS: 0*/
layout(location = 0) out vec4 color;
void main() {
color = vec4(1);
}