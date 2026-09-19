#version 450 compatibility
#include /lib/function.glsl
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex10;
uniform sampler2D colortex4;
uniform sampler2D colortex13;
in vec2 texcoord;
layout(location = 0) out vec4 finalcolor;

void main() {
     float alpha_g=texture(colortex8, texcoord).g;
    vec4 alpha_color = texture(colortex3, texcoord);
    vec4 color = texture(colortex0, texcoord);
 
    if (alpha_color.a < 0.001) {
        finalcolor.rgb = color.rgb;
        return;
    }
alpha_color.rgb = pow(alpha_color.rgb, vec3(2.2));
vec4 alpha_reflect_color=texture(colortex9, texcoord);
 if (alpha_g > 0.5) {
         finalcolor.rgb =alpha_reflect_color.rgb+0.125*color.rgb;
          finalcolor.rgb+=texture(colortex13, texcoord).rgb;
         return;
    }
float alpha_t=texture(colortex8, texcoord).r;
    finalcolor.rgb = alpha_color.rgb*color.rgb+alpha_reflect_color.rgb*alpha_t;
    finalcolor.rgb+=texture(colortex13, texcoord).rgb*pow(texture(colortex4,texcoord).g,2);

}