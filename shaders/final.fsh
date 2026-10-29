#version 450 compatibility
#include "/lib/function.glsl"
in vec2 texcoord;
/* RENDERTARGETS: 0,14 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 data;


void main() {
color.rgb = texture2DLod(colortex0, texcoord, 0.0).rgb;

    color.a = 1.0;
    color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
            ivec2 uv = ivec2(gl_FragCoord.xy);
    data = texelFetch(colortex14, uv, 0);
    #ifdef TAA
      if(uv.x==5&&uv.y==1)
	   {
	
		   data=vec4(djlitter,0,1);
		  return;
	   }
    #endif
}
