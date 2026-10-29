

uniform float frameTimeCounter;


//2Dperlin
vec4 permute(vec4 x)
{
    return mod(((x * 34.0) + 1.0) * x, 289.0);
}

vec4 taylorInvSqrt(vec4 r)
{
    return 1.79284291400159 - 0.85373472095314 * r;
}

float fade(float t)
{
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

// ------------------------------------------------------------
// 2D Perlin Noise
// 输入：连续二维坐标
// 输出：近似 [0, 1]
// ------------------------------------------------------------

float perlin2D_01(vec2 P)
{
    vec2 Pi = floor(P);
    vec2 Pf = fract(P);

    Pi = mod(Pi, 16.0);

    // 四个格点的整数坐标
    vec4 ix = Pi.x + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 iy = Pi.y + vec4(0.0, 0.0, 1.0, 1.0);

    // 格点哈希
    vec4 i = permute(permute(ix) + iy);

    // 生成梯度分量
    vec4 gx = 2.0 * fract(i / 41.0) - 1.0;
    vec4 gy = 2.0 * fract(i / 41.0 + 0.5) - 1.0;

    // 归一化梯度
    vec4 len2 = gx * gx + gy * gy;
    vec4 invlen = taylorInvSqrt(len2);

    gx *= invlen;
    gy *= invlen;

    // 四个格点对应的相对坐标
    vec4 dx = vec4(
        Pf.x,
        Pf.x - 1.0,
        Pf.x,
        Pf.x - 1.0
    );

    vec4 dy = vec4(
        Pf.y,
        Pf.y,
        Pf.y - 1.0,
        Pf.y - 1.0
    );

    // 梯度点积
    vec4 dots = gx * dx + gy * dy;

    // 五次平滑插值
    vec2 f = vec2(
        fade(Pf.x),
        fade(Pf.y)
    );

    float x1 = mix(dots.x, dots.y, f.x);
    float x2 = mix(dots.z, dots.w, f.x);

    float value = mix(x1, x2, f.y);

    return clamp(value * 0.5 + 0.5, 0.0, 1.0);
}



float perlinFBM2D(vec2 uv)
{
    float n = 0.0;
    float amplitude = 0.5;
    float totalAmplitude = 0.0;

    // 四个 octave
    for (int i = 0; i < 4; i++)
    {
        vec2 sampleuv=mod(uv,16)/16.0;
        n += amplitude * texture2DLod(perlin,sampleuv,0).r;
        totalAmplitude += amplitude;

        uv = uv * 2.0 + vec2(17.13, 9.21);
        amplitude *= 0.5;
    }

    return n / totalAmplitude;
}


// 输入：高度（米）
// 输出：散射系数（m^-1）
float localsigema(vec3 p)
{
    const float referenceScattering = 0.01;
       const float referenceHeight = 0;
    const float heightFalloff =0.075;
float height =  (length(p - earth_core_position) - MC_r);
    float h = abs(height - referenceHeight);
   float dh=sun_theta_s*sun_theta_s*sun_theta_s*sun_theta_s*exp(
        -heightFalloff * h
    );
   vec3 newp = spherical_unmapping(p);
    vec2 worldp=newp.xz+cameraPosition.xz;
    vec2 wind=0.125*frameTimeCounter*vec2(-1,0);
float dxz=perlinFBM2D(0.005*worldp+wind);//0.05,0.0375
dxz= pow(dxz,2);//2,3.5

    return referenceScattering * dh*dxz;
}
vec3 fogmodel(vec3  pixel_world,vec3 color,float depth,vec3 beginpostion,vec2 light)
{
 vec3 allcolor=color;
    
float rm_all_l=length(pixel_world);

vec3 rm_v=normalize(pixel_world);
float t1=intersectEarthT1(rm_v,beginpostion);
float t2=intersectEarthT2(rm_v,beginpostion);
if(depth==1.0)
{
 rm_all_l=t2-t1;
}
if(rm_all_l<0.275)
{
  return allcolor;
}
if(rm_all_l/MC_atom_height<0.00)
{
  return allcolor;
}
if( rm_all_l==-1.0)return allcolor;
float rm_t=FOG_STEPS;
float rm_dx=rm_all_l/rm_t;
			float pixel_sun_theta_c=dot(rm_v,sun_world);
      float rayleigh_phase=(3/(16*PI))*(1+pixel_sun_theta_c*pixel_sun_theta_c);
        float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*pixel_sun_theta_c, 1.5);
        			float opixel_sun_theta_c=1;
      float orayleigh_phase=(3/(16*PI))*(1+opixel_sun_theta_c*opixel_sun_theta_c);
        float omie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*opixel_sun_theta_c, 1.5);
        float pixel_moon_theta_c=-dot(rm_v,sun_world);
      float moon_rayleigh_phase=(3/(16*PI))*(1+pixel_moon_theta_c*pixel_moon_theta_c);
        float moon_mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*pixel_moon_theta_c, 1.5);
vec3 rm_p=rm_all_l*rm_v+beginpostion+t1*rm_v+0.5*rm_v*rm_dx;

float rm_sun_sign=1;
if(sun_theta_c<0)rm_sun_sign=0;
vec3 p_skycolor=vec3(0);
int skyrefresht=SIDE_SCATTER_INTERVAL;
float dmscatter=1-pow((1.0/gfFogBase),rm_dx/MC_atom_height);
vec3 drscateer=vec3(1-pow(sun_atten_r,rm_dx/MC_atom_height),1-pow(sun_atten_g,rm_dx/MC_atom_height),1-pow(sun_atten_b,rm_dx/MC_atom_height));
vec3 rm_step_scatter=scatterf(rm_dx/MC_atom_height);
float rm_step_fog=fog_kk(rm_dx/MC_atom_height,sun_theta_s);
for(int i=1;i<rm_t+1;i++)
{
    float rm_r=length(rm_p-earth_core_position);
	if(rm_r>MC_ar)
	{
    	rm_p-=rm_v*rm_dx;
continue;
	}

vec3 rm_shadowViewPos = (shadowModelView * vec4(rm_p, 1.0)).xyz;
	vec4 rm_shadowClipPos = shadowProjection * vec4(rm_shadowViewPos, 1.0);
     rm_shadowClipPos.z -= 0.000001;
      // apply bias
      rm_shadowClipPos.xyz = distortShadowClipPos(rm_shadowClipPos.xyz);
      vec3 rm_shadowNDCPos=rm_shadowClipPos.xyz/rm_shadowClipPos.w;
            vec3 rm_shadowScreenPos = rm_shadowNDCPos * 0.5 + 0.5;
      vec3 shadow=vec3(1,1,1);
bool inShadowFrustum = all(lessThan(abs(rm_shadowNDCPos.xyz), vec3(1.0)));
if(inShadowFrustum){
    vec3 rm_shadowScreenPos = rm_shadowNDCPos * 0.5 + 0.5;
    shadow = getShadow(rm_shadowScreenPos); 
}
  vec3 o_color=allcolor*rm_step_scatter;
o_color*=(1-rm_step_fog);
vec3 scatter_color=vec3(0);
float sun_to_rm_p = sunRayAtmLength(rm_p, sun_world);
  vec3 p_suncolor=light_color*scatterf(sun_to_rm_p/MC_atom_height)*(1-fog_kk(sun_to_rm_p/MC_atom_height,sun_theta_s));
 if(depth==1.0)
 {
  #ifdef Realtime_Sky
  p_suncolor*=sunCanReachPoint(rm_p, sun_world);
  #endif
 }
 if(depth!=1.0)p_suncolor*=rm_sun_sign;
    float moon_to_rm_p = sunRayAtmLength(rm_p, -sun_world);
 vec3 p_mooncolor=moon_color*scatterf(moon_to_rm_p/MC_atom_height)*(1-fog_kk(moon_to_rm_p/MC_atom_height,sun_theta_s));
  if(depth==1.0)
 {
    #ifdef Realtime_Sky
  p_mooncolor*=sunCanReachPoint(rm_p, -sun_world);
    #endif
 }
 if(depth!=1.0)p_mooncolor*=(1-rm_sun_sign);
  vec3 p_allcolor= p_suncolor+p_mooncolor;
//大气 //
{
  //光路前面的所有光透过该微元的反应

  //太阳照亮的微元光
 {
//sun
{


 vec3 drcolor=p_suncolor*drscateer*rayleigh_phase;
 vec3 dmcolor=mie_phase*p_suncolor*dmscatter;
 vec3 dcolor=(dmcolor+drcolor);
 if(rm_sun_sign>0.5)dcolor*=shadow;
    scatter_color+=dcolor;
}
      //moon
      //if(rm_sun_sign<0.5)
{

 vec3 drcolor=p_mooncolor*drscateer*moon_rayleigh_phase;
vec3 dmcolor=moon_mie_phase*p_mooncolor*dmscatter;
vec3  dcolor=(dmcolor+drcolor)*shadow;;
   scatter_color+=dcolor;
}
       #if Side_Scatter == 1
if((i-1)%skyrefresht==0)
	     {
				uint t=SIDE_SCATTER_SAMPLES; 
for(uint i=0;i<t;i++)
{
	vec3 p =HammersleySphereDir(i,t);
 vec3 tempcolor= skylightfogmodel(p, rm_p)+skybackground(p,vec2(0,9),1,1).rgb;
 	float p_main_theta_c=dot(rm_v,p);
      float prayleigh_phase=(3/(16*PI))*(1+p_main_theta_c*p_main_theta_c);
        float pmie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*p_main_theta_c, 1.5);
p_skycolor+=tempcolor*drscateer*prayleigh_phase;
p_skycolor+=tempcolor*dmscatter*pmie_phase;
}
p_skycolor/=(t+1);
p_skycolor*=4*PI;
p_skycolor*=light.g;
      }
       # endif
       //
       #if Side_Scatter == 0
              p_skycolor=vec3(0);
              vec3 g_color=p_allcolor*(dmscatter+drscateer)*light.g;
              p_skycolor=g_color*(1.0/(4*PI));
   # endif
      scatter_color+=p_skycolor;
 }
  }
  //大气//
   //局部雾气
if(rm_r<MC_r+50)
   {
   



float sigmaS = localsigema(rm_p);
float dxmeter=rm_dx;
float opticalDepth = sigmaS * dxmeter;
float T = exp(-opticalDepth);
float optical=1-T;
o_color*=T;
scatter_color+=p_suncolor * mie_phase *  optical*shadow;
scatter_color+=p_mooncolor * moon_mie_phase*  optical*shadow;
vec3 g_color=p_allcolor*opticalDepth*pow(light.g,2);
scatter_color+=g_color*(1.0/(4*PI));
   }
allcolor=o_color+scatter_color;
rm_p-=rm_v*rm_dx;
}
return  allcolor;
}