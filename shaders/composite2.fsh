const bool colortex1Clear = false;
#version 450 compatibility
uniform sampler2D colortex0;
uniform sampler2D colortex9;
uniform sampler2D colortex8;
uniform sampler2D colortex3;
in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 finalcolor;
void main() {
vec4 alpha_color=texture(colortex3, texcoord);
alpha_color.rgb = pow(alpha_color.rgb, vec3(2.2));
vec4 alpha_reflect_color=texture(colortex9, texcoord);
vec4 color=texture(colortex0, texcoord);
float alpha_t=texture(colortex8, texcoord).r;
finalcolor.rgb = alpha_color.rgb*color.rgb+alpha_reflect_color.rgb*alpha_t;
if(alpha_color==vec4(0))
{
  finalcolor.rgb=color.rgb;
  return;
}
/*if(texture(colortex8, texcoord).g>0)
{
  finalcolor.rgb=alpha_reflect_color.rgb*alpha_t+color.rgb*(1-alpha_t);
}*/
} 