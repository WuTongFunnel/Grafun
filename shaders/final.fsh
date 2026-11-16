#version 450 compatibility
#include "/lib/function.glsl"
in vec2 texcoord;
// final.fsh writes the screen backbuffer, not a second colortex output.
layout(location = 0) out vec4 color;

// Former composite12 ACES transform. This is applied before display gamma
// in the existing final fullscreen pass, eliminating one full-screen
// colortex0 round trip and a render-target transition.
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
    col *= TONEMAP_GAIN;
    vec3 aces = LinearToACES * col;
    aces = rrt_and_odt_fit(aces);
    return ACESToLinear * aces;
}


void main()
{
    vec3 hdr = texture2DLod(colortex0, texcoord, 0.0).rgb;
    color = vec4(pow(ACESFull(hdr), vec3(1.0 / 2.2)), 1.0);
}
