vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}
  vec3 pixel_to_world(sampler2D depthtex,vec2 texcoord)
  {
    float depth = texture(depthtex, texcoord).r;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
return feetPlayerPos;
  }
  vec3 rotateVectorAroundAxis(vec3 v, vec3 axis, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return vec3(
        (oc * axis.x * axis.x + c) * v.x + (oc * axis.x * axis.y - axis.z * s) * v.y + (oc * axis.x * axis.y + axis.y * s) * v.z,
        (oc * axis.x * axis.y + axis.z * s) * v.x + (oc * axis.y * axis.y + c) * v.y + (oc * axis.y * axis.z - axis.x * s) * v.z,
        (oc * axis.x * axis.z - axis.y * s) * v.x + (oc * axis.y * axis.z + axis.x * s) * v.y + (oc * axis.z * axis.z + c) * v.z
    );
  }
    float E(vec3 m)
    {
      float Er=0.213;
      float Eg=0.715;
      float Eb=0.072;
      return Er*m.r+Eg*m.g+Eb*m.b;
    }
float kt=1;
vec4 spherical_mapping(vec4 p)
{
  float lpxz=length(vec2(p.x,p.z));
 if(lpxz < 0.001)
{
    return p; 
}

vec3 pixel_world=p.xyz+cameraPosition.xyz;
float pixel_r=pixel_world.y-MC_sealevel+MC_r;
if(lpxz >0.5*PI*MC_r)
{
     vec4 fp= vec4(pixel_world.x,-10000,pixel_world.z,1);
     fp.xyz-= cameraPosition.xyz;
     return fp;
}
float camera_r=gfCameraRadius;
if(lpxz/MC_r<0.001)
{
  return p;
}
vec4 fp=vec4((p.x/lpxz)*pixel_r*sin(lpxz/MC_r),pixel_r*cos(lpxz/MC_r)-camera_r,(p.z/lpxz)*pixel_r*sin(lpxz/MC_r),1);
return fp;
}
vec3 spherical_unmapping(vec3 q)
{
    float h = length(q.xz);

    // 原函数的小水平距离分支直接返回输入
    if (h < 0.001 || h / MC_r < 0.001)
    {
        return q;
    }

    float camera_r = gfCameraRadius;

    // 恢复球面坐标中的竖直分量
    float vertical = q.y + camera_r;

    // 恢复原来的球面半径
    float pixel_r = length(vec2(h, vertical));

    // 恢复球面角度
    float theta = atan(h, vertical);

    // 恢复原始水平距离
    float lpxz = theta * MC_r;

    // 恢复原始 x、z 方向
    vec2 dir = q.xz / h;

    float px = dir.x * lpxz;
    float pz = dir.y * lpxz;

    // 恢复原始 y 坐标
    float py = pixel_r
             + MC_sealevel
             - MC_r
             - cameraPosition.y;

    return vec3(px, py, pz);
}
        vec3 screenxyz_to_worldxyz(vec4 p)
        {
vec4 NDC_Pos=p*2-1;
	vec4 view_dir=gbufferProjectionInverse*NDC_Pos;
	view_dir.xyz/=view_dir.w;
	vec3 pixel_view=normalize(view_dir.xyz);
		vec3 pixel_world=mat3(gbufferModelViewInverse)*pixel_view;
return pixel_world;
        }
  
        vec3 scatterf(float l)
        {
#if RAYLEIGH_DENSITY != 100
    l *= float(RAYLEIGH_DENSITY) / 100.0;
#endif
         return vec3(pow(sun_atten_r,l),pow(sun_atten_g,l),pow(sun_atten_b,l));
        }
