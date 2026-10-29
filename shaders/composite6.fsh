#version 450 compatibility
#include "/lib/function.glsl"
in vec2 texcoord;
/* RENDERTARGETS: 0,7 */
layout(location = 0) out vec4 finalcolor;
layout(location = 1) out vec4 Lcolor;
void main() {
vec3 hdr = max(texture(colortex0, texcoord).rgb, vec3(0.0));

float luminance = max(E(hdr), 1e-10);

Lcolor = vec4(log2(luminance), 0.0, 0.0, 1.0);

    float alpha_g=texture(colortex8, texcoord).g;
     finalcolor = texture(colortex0, texcoord);
            			#ifdef DISTANT_HORIZONS
if(gfDhFrontSky(texcoord))
#else
if(texture(depthtex0, texcoord).r==1.0)
#endif
	{
		return;
	}
          float alpha_t=texture(colortex8, texcoord).r;
          if (alpha_g > 0.5) {
        return;
    }
      if (alpha_t < 0.001&&wetness<0.01) {
        return;
    }
        vec3 alpha_color = texture(colortex3, texcoord).rgb;
 float dx = gfPixelSize.x;
float dy = gfPixelSize.y;
float range = REFLECTION_BLUR;   // 采样半径，单位：像素

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
#if REFLECTION_STRENGTH != 100
    reflect_color *= float(REFLECTION_STRENGTH) / 100.0;
#endif
 if (alpha_t < 0.001&&wetness>0.01) {
    finalcolor.rgb+=wetness*reflect_color;
        return;
    }
finalcolor.rgb+=reflect_color;

}