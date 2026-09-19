#version 450 compatibility
#include /lib/function.glsl
uniform sampler2D colortex3;
uniform sampler2D colortex12;
uniform sampler2D colortex0;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform float viewHeight;
uniform float viewWidth;
in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 finalcolor;

void main() {
    float alpha_g=texture(colortex8, texcoord).g;
     finalcolor = texture(colortex0, texcoord);
          float alpha_t=texture(colortex8, texcoord).r;
          if (alpha_g > 0.5) {
        return;
    }
      if (alpha_t < 0.001) {
        return;
    }
        vec3 alpha_color = texture(colortex3, texcoord).rgb;
 float dx = 1.0 / viewWidth;
float dy = 1.0 / viewHeight;
float range = 1.0;   // 采样半径，单位：像素

vec4 testcolor = vec4(0.0);
float count = 0.0;

// y轴范围，围绕当前texcoord.y
float yMin = max(texcoord.y - range * dy, 0.0);
float yMax = min(texcoord.y + range * dy, 1.0);

// x轴范围，围绕当前texcoord.x
float xMin = max(texcoord.x - range * dx, 0.0);
float xMax = min(texcoord.x + range * dx, 1.0);

for(float i = yMin; i <= yMax; i += dy)
{
    for(float j = xMin; j <= xMax; j += dx)
    {
        testcolor += texture(colortex12, vec2(j, i));
        count += 1.0;
    }
}
vec4 avgColor = testcolor / count;
vec3 reflect_color=avgColor.rgb;
finalcolor.rgb+=alpha_color*reflect_color*alpha_t;
}