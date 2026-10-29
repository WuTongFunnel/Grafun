#version 450 compatibility
#include "/lib/function.glsl"
#include "/lib/setting.glsl"
const bool colortex7Clear = false;
in vec2 texcoord;
const bool colortex8MipmapEnabled = true;
/* RENDERTARGETS: 7 */
layout(location = 0) out vec4 color;
void main() {
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    color = texelFetch(colortex7, pixel, 0);
float pre= texelFetch(colortex7, ivec2(0,0), 0).a;
if (pixel.x == 0 && pixel.y == 0)
{
        float samplestep=32;
    float dx=samplestep/viewWidth;
float dy=samplestep/viewHeight;
    vec4 testcolor=vec4(0);
    float maxl=0;
    float count=0;

    for(float i=0;i<=1;i+=dy)
    {
            for(float j=0;j<=1;j+=dx)
        {
           testcolor=texture(colortex0, vec2(j,i));
           maxl+=(E(testcolor.rgb)/E(vec3(1)));
           count+=1.0;
        }
    }
        maxl/=count;
#if Auto_Expousre_Mode == 1
float maxt=999;
            float mint = 0.000075;
        #else
        float maxt=0.05;
            float mint = 0.00675;
        #endif
    maxl = clamp(maxl, mint, maxt);
      vec4 sun_pixel=gbufferProjection*vec4(sun_view, 0.0);
   sun_pixel/= sun_pixel.w;
   vec2 sun_uv = sun_pixel.xy * 0.5 + 0.5;
float sampledepth=0;
if(all(greaterThan(sun_uv.xy, vec2(1e-6))) && all(lessThan(sun_uv.xy, vec2(1.-1e-6)))&&sun_view.z<0)sampledepth = texture(depthtex0, sun_uv).r;

if(sampledepth==1.0) 
{
    maxl=maxt;
}
            color.a=(0.03*maxl+0.97*pre);
}
}