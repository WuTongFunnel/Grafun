#version 330 compatibility
const bool colortex7Clear = false;
uniform sampler2D colortex7;
uniform sampler2D colortex0;
uniform float viewHeight;
uniform float viewWidth;
in vec2 texcoord;
/* RENDERTARGETS: 7 */
layout(location = 0) out vec4 color;

void main() {
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    color = texelFetch(colortex7, pixel, 0);
float pre= texelFetch(colortex7, ivec2(0,0), 0).a;
if (pixel.x == 0 && pixel.y == 0)
{
    float dx=64/viewWidth;
float dy=64/viewHeight;
    vec4 testcolor=vec4(0);
    float maxl=0;
    float count=0;
    float step=8;
    for(float i=0;i<=1;i+=dy)
    {
            for(float j=0;j<=1;j+=dx)
        {
           testcolor=texture(colortex0, vec2(j,i));
           maxl+=(length(testcolor.rgb)/sqrt(3.0));
           count+=1.0;
        }
    }
        maxl/=count;
    color.a=(0.03*maxl+0.97*pre);
}
}