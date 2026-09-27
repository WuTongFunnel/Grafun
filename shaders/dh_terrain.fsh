#version 450 compatibility

uniform float alphaTestRef;

// 输入名字和 VS 完全对应，无 gl_
in vec2 vLightCoord;
in vec4 vColor;
in vec3 vNormal;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 fragLight;
layout(location = 2) out vec4 fragNormal;

void main() {
    fragColor = vColor;
    fragColor.a = 1.0;

    fragLight = vec4(vLightCoord, 0.0, 1.0);
    fragNormal = vec4(vNormal * 0.5 + 0.5, 1.0);

    if(fragColor.a < alphaTestRef) discard;
}