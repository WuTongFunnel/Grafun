#version 330 compatibility
uniform sampler2D colortex0;
uniform sampler2D colortex4;
in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 finalcolor;

void main() {
vec4 alpha_color=texture(colortex4, texcoord);
vec4 color=texture(colortex0, texcoord);
float alpha_t=alpha_color.a ;
finalcolor.rgb=color.rgb*(1-alpha_t)+alpha_color.rgb*alpha_t;
}