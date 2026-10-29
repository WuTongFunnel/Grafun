
#version 450 compatibility
const bool colortex1Clear = false;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D colortex1;
uniform float alphaTestRef = 0.1;
uniform int renderStage;
const bool colortex0MipmapEnabled = true;
const bool colortex14MipmapEnabled = true;
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
out float gl_FragDepth; 
/* RENDERTARGETS: 0*/
layout(location = 0) out vec4 color;
void main() {
color = texture(gtexture, texcoord) * glcolor;
gl_FragDepth = gl_FragCoord.z;
	if (color.a < alphaTestRef) {
		discard;
	}
}