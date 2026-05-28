#version 450 compatibility
uniform sampler2D colortex0;  
uniform sampler2D colortex6;  
uniform sampler2D colortex4;  
uniform sampler2D colortex8;  
uniform sampler2D colortex9;  
uniform sampler2D colortex3;  
in vec2 texcoord;
/* RENDERTARGETS: 0,6*/  
layout(location = 0) out vec4 finalColor;
layout(location = 1) out vec4 bloomcolor;
const mat3 LinearToACES = mat3(
    0.59719, 0.07600, 0.02840,
    0.35458, 0.90834, 0.13383,
    0.04823, 0.01566, 0.83777
);
const mat3 ACESToLinear = mat3(
    1.60475, -0.10208, -0.00327,
    -0.53108, 1.10813, -0.07276,
    -0.07367, -0.00605, 1.07602
);
vec3 rrt_and_odt_fit(vec3 col){
    vec3 a = col * (col + 0.0245786) - 0.000090537;
    vec3 b = col * (0.983729 * col + 0.4329510) + 0.238081;
    return a / b;
}
vec3 ACESFull(vec3 col){
    col *= 1.12;
    vec3 aces = LinearToACES * col;
    aces = rrt_and_odt_fit(aces);
    return ACESToLinear * aces;
}
void main() {
    finalColor = texture(colortex0, texcoord);
    vec4 bloomColor = texture(colortex6, texcoord);
      finalColor.rgb+=bloomColor.rgb;
finalColor.rgb = ACESFull(finalColor.rgb);
finalColor.rgb = pow(finalColor.rgb, vec3(1.0 / 2.2));  
}