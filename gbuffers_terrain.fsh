
#version 450 compatibility
const bool colortex1Clear = false;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D colortex1;
uniform int renderStage;
const bool colortex0MipmapEnabled = true;
const bool colortex14MipmapEnabled = true;
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

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 watercolor;
void main() {
	watercolor=vec4(1,1,1,0);
		if(renderStage==MC_RENDER_STAGE_RAIN_SNOW)
	{
		color =vec4(1,1,1,1);
	}
	ivec2 pixel = ivec2(gl_FragCoord.xy);
lightmapData= texelFetch(colortex1, pixel, 0);
	color = texture(gtexture, texcoord) * glcolor;
	float t=color.a;
	color.a=t;
	lightmapData = vec4(lmcoord, 0.0, 1.0);
	
encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	if (color.a <alphaTestRef) {
		discard;
	}
}