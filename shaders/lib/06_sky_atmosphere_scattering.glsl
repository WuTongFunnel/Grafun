        vec3 skylightfogmodel(vec3  pixel_world,vec3 beginpostion)
{
 vec3 allcolor=vec3(0);
    
vec3 fogskycolor=vec3(0);
float rm_all_l=length(pixel_world);
vec3 rm_v=normalize(pixel_world);
float t1=intersectEarthT1(rm_v,beginpostion);
float t2=intersectEarthT2(rm_v,beginpostion);
 rm_all_l=t2-t1;
if( rm_all_l==-1.0)return allcolor;
float rm_t=SKYLIGHT_FOG_STEPS;
float rm_dx=rm_all_l/rm_t;
			float pixel_sun_theta_c=dot(rm_v,sun_world);
      float rayleigh_phase=(3/(16*PI))*(1+pixel_sun_theta_c*pixel_sun_theta_c);
        float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*pixel_sun_theta_c, 1.5);
        			float pixel_moon_theta_c=-dot(rm_v,sun_world);
      float moon_rayleigh_phase=(3/(16*PI))*(1+pixel_moon_theta_c*pixel_moon_theta_c);
        float moon_mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*pixel_moon_theta_c, 1.5);
        			float opixel_sun_theta_c=1;
      float orayleigh_phase=(3/(16*PI))*(1+opixel_sun_theta_c*opixel_sun_theta_c);
        float omie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*opixel_sun_theta_c, 1.5);
vec3 rm_p=rm_all_l*rm_v+0.5*rm_v*rm_dx+t1*rm_v+beginpostion;
float rm_sun_sign=1;
if(sun_theta_c<0)rm_sun_sign=0;
   vec3 dscateer=gfRayleighCoeff*rm_dx;
 float dmscatter=gfMieCoeff*rm_dx;
// 步长在本次射线积分中固定；这些结果仍随射线变化。
vec3 rm_step_scatter=scatterf(rm_dx/MC_atom_height);
float rm_step_fog=fog_kk(rm_dx/MC_atom_height,sun_theta_s);
for(int i=1;i<rm_t+1;i++)
{
	if(length(rm_p-earth_core_position)>MC_ar)
	{
    	rm_p-=rm_v*rm_dx;
continue;
	}
vec3 rm_shadowViewPos = (shadowModelView * vec4(rm_p, 1.0)).xyz;
vec4 rm_shadowClipPos = shadowProjection * vec4(rm_shadowViewPos, 1.0);
rm_shadowClipPos.z -= 0.000001;
rm_shadowClipPos.xyz = distortShadowClipPos(rm_shadowClipPos.xyz);
vec3 rm_shadowNDCPos=rm_shadowClipPos.xyz/rm_shadowClipPos.w;

vec3 shadow=vec3(1);
// 次级天空光射线，超出阴影视锥直接不采样阴影贴图
    vec3 rm_shadowScreenPos = rm_shadowNDCPos * 0.5 + 0.5;
  bool inShadowFrustum = all(lessThan(abs(rm_shadowNDCPos.xyz), vec3(1.0)));
if(inShadowFrustum){
    vec3 rm_shadowScreenPos = rm_shadowNDCPos * 0.5 + 0.5;
    shadow = getShadow(rm_shadowScreenPos); 
} 

  //光路前面的所有光透过该微元的反应
  vec3 o_color=allcolor*rm_step_scatter;
  

o_color=o_color*(1-rm_step_fog);
//vec3 new_r_color=(allcolor-o_color)*orayleigh_phase;
  // vec3 new_m_color=o_color*rm_step_fog*omie_phase;
   //vec3 new_color=new_r_color+new_m_color;
   allcolor=o_color;
  //太阳照亮的微元光
 vec3 p_skycolor=vec3(0);
  vec3 p_allcolor=vec3(0);
{
 // 
// 
  {
  //sun
 float sun_to_rm_p = sunRayAtmLength(rm_p, sun_world);
 vec3 p_suncolor=light_color*scatterf(sun_to_rm_p/MC_atom_height)*(1-fog_kk(sun_to_rm_p/MC_atom_height,sun_theta_s));
if(rm_sun_sign>0.5)p_allcolor+=p_suncolor;
  p_suncolor*=sunCanReachPoint(rm_p, sun_world);

 vec3 drcolor=p_suncolor*dscateer*rayleigh_phase;
  vec3 dmcolor=mie_phase*p_suncolor*dmscatter;
 vec3 dcolor=(dmcolor+drcolor);
  if(rm_sun_sign>0.5)dcolor*=shadow;
     allcolor+=dcolor;
  }
   if(rm_sun_sign<0.5)
   {
 //moon
  float moon_to_rm_p = sunRayAtmLength(rm_p, -sun_world);
 vec3 p_mooncolor=moon_color*scatterf(moon_to_rm_p/MC_atom_height)*(1-fog_kk(moon_to_rm_p/MC_atom_height,sun_theta_s));
 p_allcolor+=p_mooncolor;
  p_mooncolor*=sunCanReachPoint(rm_p, -sun_world);
 vec3 drcolor=p_mooncolor*dscateer*moon_rayleigh_phase;
vec3 dmcolor=moon_mie_phase*p_mooncolor*dmscatter;
 vec3 dcolor=(dmcolor+drcolor)*shadow;
 
   allcolor+=dcolor;
   }
 			float pixel_sun_theta_c=dot(rm_v,sun_world);


     vec3  p_skycolor=vec3(0);
              vec3 g_color=p_allcolor*(dscateer+dmscatter);
              p_skycolor=g_color*(1.0/(4*PI));
              allcolor+=p_skycolor;
  }
	rm_p-=rm_v*rm_dx;
}
return  allcolor;
}
      vec3 HammersleySphereDir(uint i, uint sampleTotal)
{
    uint bits = i;
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    float rInv = float(bits) * 2.3283064365386963e-10;
    vec2 xi = vec2(float(i)/float(sampleTotal), rInv);
    float u = xi.x;
    float v = xi.y;
    float phi = 2.0 * PI * u;
    float z = 1.0 - 2.0 * v;
    float r = sqrt(max(0.0, 1.0 - z*z));
    return vec3(r * cos(phi), r * sin(phi), z);
}
// 输入：i样本序号，sampleTotal总样本数，N世界空间单位法线
// 返回：世界空间入射方向wi，pdf = dot(N,wi)/PI
vec3 HammersleyCosHemisphereDir(uint i, uint sampleTotal, vec3 N)
{
    // Hammersley 2D低差异序列（bit反转，和你原始代码完全一致）
    uint bits = i;
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    float rInv = float(bits) * 2.3283064365386963e-10;
    vec2 xi = vec2(float(i)/float(sampleTotal), rInv);

    // 余弦加权半球采样（局部切空间，局部z=法线方向）
    float u = xi.x;
    float v = xi.y;
    float phi = 2.0 * PI * u;
    float z = sqrt(v);
    float r = sqrt(max(0.0, 1.0 - v));
    vec3 localWi = vec3(r * cos(phi), r * sin(phi), z);

// 更稳定的TBN，避免cross接近0产生NaN
vec3 up = vec3(0.0,1.0,0.0);
if(abs(dot(N,up)) > 0.999) up = vec3(1,0,0);
vec3 T = normalize(cross(up, N));
vec3 B = cross(N, T);
mat3 TBN = mat3(T,B,N);


    return normalize(TBN * localWi);
}
