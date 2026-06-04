#version 450 compatibility

uniform sampler2D gtexture;
uniform int renderStage;
in vec2 texcoord;
in vec4 glcolor;
const float sunPathRotation=0;
flat in float isWater;
layout(location = 0) out vec4 color;

void main() {

  color = texture(gtexture, texcoord) * glcolor;
  if(color.a < 0.1){
    discard;
  }
if(isWater>0.5)color.a=0.375;
}