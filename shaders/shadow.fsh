#version 330 compatibility

uniform sampler2D gtexture;
uniform int renderStage;
in vec2 texcoord;
in vec4 glcolor;
const float sunPathRotation = 45.0;

layout(location = 0) out vec4 color;

void main() {

  color = texture(gtexture, texcoord) * glcolor;
  if(color.a < 0.1){
    discard;
  }
}