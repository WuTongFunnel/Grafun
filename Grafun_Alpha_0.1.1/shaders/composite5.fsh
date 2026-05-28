#version 450 compatibility
uniform sampler2D colortex6;
uniform sampler2D colortex0;
uniform sampler2D colortex10;
uniform float viewHeight;
uniform float viewWidth;
in vec2 texcoord;
/* RENDERTARGETS:6 */
layout(location = 0) out vec4 color;
void main() {
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    color = texelFetch(colortex6, pixel, 0);
    int dx=1;
int dy=1;
    vec4 testcolor=vec4(0);
    float count=0;
     int step=0;
    for(int i=max(pixel.y-step*dy,0);i<=min(pixel.y+step*dy,viewHeight-1);i+=dy)
    {
            for(int j=max(pixel.x-step*dx,0);j<=min(pixel.x+step*dx,viewWidth-1);j+=dx)
        {
           testcolor+=texelFetch(colortex6, ivec2(j,i),0);
           count+=1.0;
        }
    }
    
    testcolor/=count;
    color=testcolor;
}