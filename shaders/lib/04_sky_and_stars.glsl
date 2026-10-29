       vec4 skybackground(vec3 pixel_world,vec2 texcoord,float depth,float r)
       {  
        float pixel_world_theta_c=dot(pixel_world, vec3(0,1,0));
        vec4 color=vec4 (0,0,0,1);
//天空背景渲染

//计算大气折射逆真实向量
float unref_false_theta=asin(pixel_world_theta_c);
vec3  unref_pixel_world=pixel_world;
if(r<MC_ar)
{
float unref_a=1;
float unref_true_theta= asin(unref_a*pixel_world_theta_c);

vec2 unref_temp=normalize(vec2(pixel_world.x,pixel_world.z));
 unref_pixel_world=normalize(vec3(unref_temp.r,tan(unref_true_theta),unref_temp.g));
}
// 顶点阶段按原顺序合成三次旋转，片元阶段只变换当前视线。
vec3 dir = gfStarRotation * unref_pixel_world;

// 5. 计算最终UV
float lon = atan(dir.z, dir.x);
float lat = acos(-dir.y);
vec2 uv = vec2(lon / (2.0 * PI) + 0.5, lat / PI);
// 6. 采样星空
vec4 starcolor = texture(starmap, uv);
if(r>0)
{
  starcolor=STAR_BRIGHTNESS*sunk*(1.0/400000) * texture(starlightmap, uv);
  color.rgb=starcolor.rgb;
  return  color;
}
if(depth==1.0)
{
color.rgb=STAR_BRIGHTNESS*sunk*(1.0/400000) * starcolor.rgb;
	//太阳渲染
  vec4 sunredercolor=texture(colortex11,texcoord);
		if(sunredercolor.a>0.5)
			{
				color.rgb=sunredercolor.rgb;
			}
      {
        color.rgb=moon( unref_pixel_world,color.rgb);
      }
      
}
return color;
       }

vec4 sky(vec2 texcoord,float depth,float r)
{
 vec4 color=vec4(0,0,0,1);
vec3 pixel_world=screenxyz_to_worldxyz(vec4(texcoord,depth,1));
color=skybackground(pixel_world,texcoord, depth,0);
return color;
}
vec4 reflect_sky(vec3 pixel_world,float pixely)
{
 vec4 color=vec4(0,0,0,1);
color+=skybackground(pixel_world,vec2(0,0), 1,1);
return color;
}
