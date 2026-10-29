#version 450 compatibility

// 只用 DH 官方允许的属性名，绝对不用 gl_
in vec3 aPosition;
in vec3 aNormal;
in vec4 aColor;
in vec2 aLightCoord;

// 输出绝不使用 gl_ 开头！
out vec2 vLightCoord;
out vec4 vColor;
out vec3 vNormal;

void main() {
    gl_Position = ftransform();

    vNormal = normalize(gl_NormalMatrix * aNormal);
    vColor = aColor;
    vLightCoord = aLightCoord;
}