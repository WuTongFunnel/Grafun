#version 450 compatibility
/*
const int colortex3Format = RGBA16F;
*/
uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D depthtex0;
uniform float alphaTestRef = 0.1;
uniform float glass;
uniform sampler2D colortex8;
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

in vec3 normal;
flat in float isWater;
/* RENDERTARGETS: 3,4,5,8 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 alpha;
void main() {
		float depth = texture(depthtex0, gl_FragCoord.xy).r;
	color = texture(gtexture, texcoord) * glcolor;
	color.rgb=vec3(1);
	lightmapData = vec4(0,1, 0.0, 1.0);
encodedNormal = vec4(vec3(0,1,0) * 0.5 + 0.5, 1.0);
	alpha=vec4(1.0,1,1,1);
	color.a=1;
	
}