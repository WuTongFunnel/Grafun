#version 450 compatibility
#include "/lib/function.glsl"
in vec2 texcoord;
/*
const int colortex0Format = RGBA16F;
*/
layout(location = 0) out vec4 finalcolor;

void main() {
     float alpha_g=texture(colortex8, texcoord).g;
    vec4 alpha_color = texture(colortex3, texcoord);
    vec4 color = texture(colortex0, texcoord);
    float depth = texture(depthtex1, texcoord).r;
   
alpha_color.rgb = pow(alpha_color.rgb, vec3(2.2));
vec4 alpha_reflect_color=texture(colortex9, texcoord);
#if defined(DISTANT_HORIZONS) && defined(Realtime_Sky)
// Extend the existing atmosphere through the segment behind a translucent
// surface when its opaque background is DH terrain. The camera-to-front
// segment is still handled exactly once in composite4.
if (gfDhOpaqueAt(texcoord) && gfDhHasTranslucent(texcoord))
{
    vec3 frontPos = texture(colortex15, texcoord).rgb;
    if (gfDhFrontAt(texcoord)) frontPos = gfDhPlayerPosition(texcoord, textureLod(dhDepthTex0, texcoord, 0.0).r);
    vec3 backPos = gfDhPlayerPosition(texcoord, textureLod(dhDepthTex1, texcoord, 0.0).r);
    color.rgb = fogmodel(backPos - frontPos, color.rgb, 0.5, frontPos, texture(colortex1, texcoord).rg);
}
#endif
 if (alpha_g > 0.5) {
         finalcolor.rgb =(0.5*alpha_reflect_color.rgb+0.48*color.rgb);
     
         return;
    }
     			#ifdef DISTANT_HORIZONS
if(gfDhOpaqueSky(texcoord))
#else
if(depth==1.0)
#endif
	{
        finalcolor=color;
		return;
	}

float alpha_t=texture(colortex8, texcoord).r;
    finalcolor.rgb = alpha_color.rgb*color.rgb+alpha_reflect_color.rgb*alpha_t;
    
}