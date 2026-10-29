#version 450 compatibility

uniform int renderStage;
#include "/lib/09_vertex_common.glsl"
uniform sampler2D gtexture;
in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 watercolor;
void main() {
	watercolor=vec4(1,1,1,0);
	color=vec4(0,0,0,1);
	if(renderStage==MC_RENDER_STAGE_RAIN_SNOW)
	{
	color =sunk* texture(gtexture, texcoord) * glcolor;
	}
}
