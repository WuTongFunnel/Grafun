#version 330 compatibility

uniform sampler2D gtexture;
uniform int renderStage;
uniform float alphaTestRef = 0.1;
uniform mat4 gbufferProjectionInverse;
uniform sampler2D depthtex0;
in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	
	color = texture(gtexture, texcoord) * glcolor;
	//屏蔽太阳
	if (renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON)
{
    color.a=0;
}

}