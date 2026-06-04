#version 450 compatibility
#include "/lib/setting.glsl"
uniform sampler2D colortex0;  
uniform sampler2D colortex7;
in vec2 texcoord;
/* RENDERTARGETS: 0,6*/  
layout(location = 0) out vec4 finalColor;
layout(location = 1) out vec4 bloomcolor;
void main() {
    finalColor = texture(colortex0, texcoord);
float t= texelFetch(colortex7, ivec2(0,0), 0).a;
#ifdef Auto_Expousre
finalColor.rgb/=2*t;
#endif
#ifndef Auto_Expousre
finalColor.rgb/=0.1;
#endif
finalColor.rgb*=Expousre_Gain;
 bloomcolor=vec4(0.0,0.0,0.0,1.0);
 if(any(greaterThan(finalColor.rgb, vec3(1.0))))
{
   bloomcolor.r = max(finalColor.r - 1.0, 0.0);
bloomcolor.g = max(finalColor.g - 1.0, 0.0);
bloomcolor.b = max(finalColor.b - 1.0, 0.0);
bloomcolor.a = 1.0;
}
}