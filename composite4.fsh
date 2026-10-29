#version 450 compatibility
#include /lib/function.glsl
in vec2 texcoord;
/*
const int colortex0Format = RGBA16F;
*/
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 finalcolor;

void main() {
     finalcolor=vec4(0,0,0,1);
             vec4 color = texture(colortex0, texcoord);
     #ifdef Realtime_Sky
    		float depth0 = texture(depthtex0, texcoord).r;
    vec4 NDC_Pos0   = vec4(texcoord, depth0, 1.0) * 2.0 - 1.0;
vec4 viewPos0   = gbufferProjectionInverse * NDC_Pos0;
viewPos0.xyz   /= viewPos0.w;
vec3 pixel_world_pos0 = (gbufferModelViewInverse * viewPos0).xyz;
    
    vec4 alpha_color = texture(colortex3, texcoord);
alpha_color.rgb = pow(alpha_color.rgb, vec3(2.2));
   float depth1 = texture(depthtex1, texcoord).r;
   float camera_r=cameraPosition.y-MC_sealevel+MC_r;
    vec4 NDC_Pos1   = vec4(texcoord, depth1, 1.0) * 2.0 - 1.0;
vec4 viewPos1   = gbufferProjectionInverse * NDC_Pos1;
viewPos1.xyz   /= viewPos1.w;
vec3 pixel_world_pos1 = (gbufferModelViewInverse * viewPos1).xyz;
   vec2 light=texture(colortex1,texcoord).rg;
   vec3 starcolor=vec3(0);
 
    
      if(depth0!=depth1)light=texture(colortex4,texcoord).rg;
          if(depth0==1.0)
     {
          color.rgb+=sky(texcoord,depth0,camera_r).rgb;
              light=vec2(0,1);
     }
if(depth0!=depth1)light=texture(colortex4,texcoord).rg;
finalcolor.rgb+=fogmodel(pixel_world_pos0,color.rgb,depth0,vec3(0),light);
          if(depth1==1.0&&depth0!=1.0)
     {
           starcolor.rgb+=sky(texcoord,depth1,camera_r).rgb;
          light=vec2(0,1);
           finalcolor.rgb+=fogmodel(pixel_world_pos1-pixel_world_pos0, starcolor.rgb,depth1,pixel_world_pos0,light)*alpha_color.rgb;
         
     }
#endif
#ifndef Realtime_Sky 
finalcolor.rgb=color.rgb;
#endif
}