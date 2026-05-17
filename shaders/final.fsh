#version 330 compatibility
uniform sampler2D colortex1;  
uniform sampler2D colortex0;  
uniform float viewWidth;
uniform float viewHeight;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex2;
in vec2 texcoord;

/* RENDERTARGETS: 0 */  
layout(location = 0) out vec4 finalColor;

void main() {

finalColor =texture(colortex0, texcoord);
    finalColor.rgb *= 2.5; 
    finalColor.rgb = pow(finalColor.rgb, vec3(1.0 / 2.2));
}