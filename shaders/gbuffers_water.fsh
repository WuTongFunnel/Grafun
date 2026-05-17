#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D depthtex0;
uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

in vec3 normal;

/* RENDERTARGETS: 3,4,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

void main() {
		float depth = texture(depthtex0, gl_FragCoord.xy).r;
	color = texture(gtexture, texcoord) * glcolor;
	lightmapData = vec4(lmcoord, 0.0, 1.0);
encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	if (color.a <alphaTestRef) {
		discard;
	}
}