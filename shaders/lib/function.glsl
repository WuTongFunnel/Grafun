#include "/lib/setting.glsl"
const float shadowDistance = 512;
// defines the total radius in which we sample (in pixels)
#define SHADOW_RADIUS 1
// controls how many samples we take for every pixel we sample
#define SHADOW_RANGE  6
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D starlightmap;
const int shadowMapResolution =4096;
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const float sunPathRotation=rotation;
const bool shadowcolor0Nearest = true;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 cameraPosition;
uniform float rainStrength;
uniform float thunderStrength;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform sampler2D colortex14;
uniform sampler2D colortex15;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D starmap;

uniform float viewHeight;
uniform float viewWidth;
uniform float aspectRatio;
uniform float wetness;
const bool colortex0MipmapEnabled = true;
const bool colortex6MipmapEnabled = true;
const bool colortex14MipmapEnabled = true;
/*
const int colortex14Format = RGBA16F;
*/
float mkt=1;


float mie_g = 0.375;
float fog_k(float sun_theta_s)
{
       float fog_world_fun_max=1.05;
			float fog_world_fun_min=1.0;
			float fog_world_fun_speed=4;
			float fog_world_fun=(fog_world_fun_max-fog_world_fun_min)*pow(sun_theta_s,2*fog_world_fun_speed)+fog_world_fun_min;
      return fog_world_fun+10*pow(rainStrength,2)+1000*pow(thunderStrength,2);
}
float fog_kk(float l2, float sun_theta_s)
{

 float mix_sky_k=1-pow(fog_k( sun_theta_s),-l2);
 return mix_sky_k;
}
vec3 distortShadowClipPos(vec3 shadowClipPos){
  float k=0.95;
  float distortionFactor = 1/(k+(1/(length(shadowClipPos.xy)))*(1-k)); // distance from the player in shadow clip space

  shadowClipPos.xy /= length(shadowClipPos.xy);
    shadowClipPos.xy*=distortionFactor;
  shadowClipPos.z *= 0.125; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky

  return shadowClipPos;
}
vec3 getShadow(vec3 shadowScreenPos){
  float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r); // sample the shadow map containing everything
  /*
  note that a value of 1.0 means 100% of sunlight is getting through
  not that there is 100% shadowing
  */

  if(transparentShadow == 1.0){
    /*
    since this shadow map contains everything,
    there is no shadow at all, so we return full sunlight
    */
    return vec3(1.0);
  }

  float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r); // sample the shadow map containing only opaque stuff

  if(opaqueShadow == 0.0){
    // there is a shadow cast by something opaque, so we return no sunlight
    return vec3(0.0);
  }

  // contains the color and alpha (transparency) of the thing casting a shadow
  vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);
shadowColor.rgb = pow(shadowColor.rgb, vec3(2.2));

  /*
  we use 1 - the alpha to get how much light is let through
  and multiply that light by the color of the caster
  */
  return shadowColor.rgb ;
}
vec3 getSoftShadow(vec4 shadowClipPos,float bias){
  vec3 shadowAccum = vec3(0.0); // sum of all shadow samples
  const int samples = SHADOW_RANGE * SHADOW_RANGE * 4; // we are taking 2 * SHADOW_RANGE * 2 * SHADOW_RANGE samples

  for(int x = -SHADOW_RANGE; x < SHADOW_RANGE; x++){
    for(int y = -SHADOW_RANGE; y < SHADOW_RANGE; y++){
      vec2 offset = vec2(x, y) * SHADOW_RADIUS / float(SHADOW_RANGE);
      offset /= shadowMapResolution; // offset in the rotated direction by the specified amount. We divide by the resolution so our offset is in terms of pixels
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.z -= bias; // apply bias
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadowAccum += getShadow(shadowScreenPos); // take shadow sample
    }
  }

  return shadowAccum / float(samples); // divide sum by count, getting average shadow
}
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
    uniform vec3 sunPosition;
    uniform float sun_atten_r;
uniform float sun_atten_g;
uniform float sun_atten_b;
uniform float sunAngle;
uniform vec3 sun_origin_base_color;
uniform vec3 light_pollution_color;
uniform float eyeAltitude;
float atom_height=100000;
float earth_factor=1000;
float earth_r=6371000;
float MC_r=(earth_r/earth_factor);
float MC_atom_height=(atom_height/earth_factor);
float MC_ar=MC_r+ MC_atom_height;
float MC_sealevel=63;
vec3 blocklightColor = 0.5*vec3(1.0, 0.5, 0.08);
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
if(lpxz >PI*MC_r)
{
     vec4 fp= vec4(pixel_world.x,-10000,pixel_world.z,1);
     fp.xyz-= cameraPosition.xyz;
     return fp;
}
float camera_r=cameraPosition.y-MC_sealevel+MC_r;
if(lpxz/MC_r<0.001)
{
  return p;
}
vec4 fp=vec4((p.x/lpxz)*pixel_r*sin(lpxz/MC_r),pixel_r*cos(lpxz/MC_r)-camera_r,(p.z/lpxz)*pixel_r*sin(lpxz/MC_r),1);
return fp;
}
	vec3 lightVector = normalize(sunPosition);
vec3 sun_world = mat3(gbufferModelViewInverse) * lightVector;

vec3 light_color=sun_origin_base_color;
float moonk=(7.5/100);
vec3 moon_color=moonk*sun_origin_base_color;
	float sun_theta_c=dot (sun_world, vec3(0,1,0));
      	float sun_theta_s=sqrt(1-pow(sun_theta_c,2));
    		  vec3 sun_view=normalize(sunPosition);


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
         return vec3(pow(sun_atten_r,l),pow(sun_atten_g,l),pow(sun_atten_b,l));
        }

       vec4 skybackground(vec3 pixel_world,vec2 texcoord,float depth,float r)
       {  
        float pixel_world_theta_c=dot(pixel_world, vec3(0,1,0));
        vec4 color=vec4 (0,0,0,1);
        // 星空渲染
const float fixedYaw   = radians(-90.0);   // 滚动
const float fixedPitch = radians(60.0);   // 上下仰
vec3 sunAxis = rotateVectorAroundAxis(vec3(0,0,1),vec3(1,0,0),radians(-rotation));

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
// 3. 太阳旋转角度（只由时间 sunAngle 驱动，无任何偏移）
float angle = sunAngle * 2*PI;

// 4. 视线星空向量 绕太阳轴旋转（关键：先旋转，再算UV）
vec3 dir = rotateVectorAroundAxis( unref_pixel_world, sunAxis, -angle);
// Yaw
dir = rotateVectorAroundAxis(dir, sunAxis, fixedYaw);
// Pitch
dir = rotateVectorAroundAxis(dir, vec3(1,0,0), fixedPitch);

// 5. 计算最终UV
float lon = atan(dir.z, dir.x);
float lat = acos(-dir.y);
vec2 uv = vec2(lon / (2.0 * PI) + 0.5, lat / PI);
// 6. 采样星空
vec4 starcolor = texture(starmap, uv);
if(r>0)
{
  starcolor=0.2 * texture(starlightmap, uv);
  color.rgb=0.002 * starcolor.rgb;
  return  color;
}
if(depth==1.0)
{
color.rgb=0.002 * starcolor.rgb;
	//太阳渲染
  vec4 sunredercolor=texture(colortex11,texcoord);
		if(sunredercolor.a>0.5)
			{
				color.rgb=sunredercolor.rgb;
			}
      if(dot(unref_pixel_world,-sun_world)>cos(radians(0.25)))
      {
        color.rgb=moonk*vec3(18867);
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
vec3 earth_core_position=vec3(0,MC_sealevel-cameraPosition.y-MC_r,0);
float intersectEarthT1(vec3 p,vec3 q)
{
    vec3 E = earth_core_position;
    vec3 oc = q - E;
    float b = 2.0 * dot(p, oc);
    float c = dot(oc, oc) - MC_ar * MC_ar;

    float delta = b*b - 4.0 * c;
    if(delta < 0.0)
    {
        return -1.0;
    }
    float sqrtDelta = sqrt(delta);
    float t1 = (-b - sqrtDelta) / 2.0;
    return max(0.0, t1);
}
// p必须是单位方向向量
float intersectEarthT2(vec3 p,vec3 q)
{
    vec3 E = earth_core_position;
    vec3 oc = q - E;
    float b = 2.0 * dot(p, oc);
    float c = dot(oc, oc) - MC_ar * MC_ar;

    float delta = b*b - 4.0 * c;
    if(delta < 0.0)
    {
        return -1.0;
    }
    float sqrtDelta = sqrt(delta);
    float t1 = (-b + sqrtDelta) / 2.0;
    return max(0.0, t1);
}

float sunRayAtmLength(vec3 P, vec3 sunDir)
{
    vec3 E = earth_core_position;
    vec3 rel = P - E;
    float A = dot(sunDir, rel);
    float lenRelSq = dot(rel, rel);
    float R = MC_ar;

    float delta = A*A - (lenRelSq - R*R);
    if(delta < 0.0) return 0.0;

    float sqrtDelta = sqrt(delta);
    float t = -A - sqrtDelta; // ✅ 负号保留，正确
    return max(max(-A - sqrtDelta,-A + sqrtDelta), 0.0);
}
const float EPS = 1e-6;

// 单位球单个球冠立体角，halfAngle 为半张角（弧度）
float capSolidAngle(float halfAngle) {
    return 2.0 * PI * (1.0 - cos(halfAngle));
}

// 两个球冠相交立体角，alpha、beta、gamma 均为弧度
// alpha: 球冠A半张角
// beta:  球冠B半张角
// gamma: 两球冠对称轴夹角
float intersectCapsSolidAngle(float alpha, float beta, float gamma) {
    alpha = clamp(alpha, 0.0, PI);
    beta  = clamp(beta,  0.0, PI);
    gamma = clamp(gamma, 0.0, PI);

    // 一个球冠覆盖整个球面，则交集等于另一个球冠
    if (alpha >= PI - EPS) return capSolidAngle(beta);
    if (beta  >= PI - EPS) return capSolidAngle(alpha);

    // 两轴几乎反向：背对背，无交集
    if (gamma >= PI - EPS) return 0.0;

    // 完全分离，无交集
    if (gamma >= alpha + beta - EPS) return 0.0;

    // 一个球冠完全包含另一个
    if (gamma <= abs(alpha - beta) + EPS)
        return capSolidAngle(min(alpha, beta));

    float sa = sin(alpha);
    float sb = sin(beta);
    float sg = sin(gamma);

    // 角度趋近0，保护除零
    if (sa < EPS || sb < EPS || sg < EPS) return 0.0;

    float lambdaA = acos(clamp(
        (cos(beta) - cos(alpha) * cos(gamma)) / (sa * sg),
        -1.0, 1.0));

    float lambdaB = acos(clamp(
        (cos(alpha) - cos(beta) * cos(gamma)) / (sb * sg),
        -1.0, 1.0));

    float lambdaP = acos(clamp(
        (cos(gamma) - cos(alpha) * cos(beta)) / (sa * sb),
        -1.0, 1.0));

    float omega = 2.0 * PI
                - 2.0 * (lambdaP
                       + lambdaA * cos(alpha)
                       + lambdaB * cos(beta));

    return clamp(omega, 0.0, capSolidAngle(min(alpha, beta)));
}

float sunCanReachPoint(vec3 P, vec3 sunDir)
{

    vec3 E = earth_core_position;
    vec3 v=normalize(E-P);
    float earth_distance = length(P - E);
    float earth_halftheta=asin(MC_r/earth_distance);
    if(earth_distance<MC_r)return 0;
    float sun_halftheta=radians(0.25);
    float sun_s=capSolidAngle(sun_halftheta);
    
    float dotVSun = dot(v, sunDir);
    dotVSun = clamp(dotVSun, -1.0, 1.0);
    float gamma = acos(dotVSun);
    
    float cross_s=intersectCapsSolidAngle(sun_halftheta,earth_halftheta,gamma);
    float sun_visible = sun_s - cross_s;
  
    return clamp(sun_visible / sun_s, 0.0, 1.0);
}


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
float rm_t=8;
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
   vec3 dscateer=vec3(-log(sun_atten_r)*rm_dx/MC_atom_height,-log(sun_atten_g)*rm_dx/MC_atom_height,-log(sun_atten_b)*rm_dx/MC_atom_height);
 float dmscatter=(log(fog_k(sun_theta_s))*rm_dx/MC_atom_height);
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
  vec3 o_color=allcolor*scatterf(rm_dx/MC_atom_height);
  

o_color=o_color*(1-fog_kk(rm_dx/MC_atom_height,sun_theta_s));
//vec3 new_r_color=(allcolor-o_color)*orayleigh_phase;
  // vec3 new_m_color=o_color*fog_kk(rm_dx/MC_atom_height,sun_theta_s)*omie_phase;
   //vec3 new_color=new_r_color+new_m_color;
   allcolor=o_color;
  //太阳照亮的微元光
 vec3 p_skycolor=vec3(0);
  vec3 p_allcolor=vec3(0);
{
 // 
 if(rm_sun_sign>0.5)
  {
  //sun
 float sun_to_rm_p = sunRayAtmLength(rm_p, sun_world);
 vec3 p_suncolor=light_color*scatterf(sun_to_rm_p/MC_atom_height)*(1-fog_kk(sun_to_rm_p/MC_atom_height,sun_theta_s));
p_allcolor+=p_suncolor;
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
   vec3 oneskylight(float l)
        {
          float p=1/(4*PI);
          vec3 color=vec3(1)*scatterf(l*(1-p))*(1-fog_kk(l*(1-p),sun_theta_s))-vec3(1)*scatterf(l)*(1-fog_kk(l,sun_theta_s));
          return color;
        }
vec3 fogmodel(vec3  pixel_world,vec3 color,float depth,vec3 beginpostion,vec2 light)
{
 vec3 allcolor=color;
    
float rm_all_l=length(pixel_world);

vec3 rm_v=normalize(pixel_world);
float t1=intersectEarthT1(rm_v,beginpostion);
if(t1>rm_all_l)return allcolor;
float t2=intersectEarthT2(rm_v,beginpostion);
if(depth==1.0)
{
 rm_all_l=t2-t1;
}
if(rm_all_l<0.275)
{
  return allcolor;
}
if( rm_all_l==-1.0)return allcolor;
float rm_t=64;
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
int skyrefresht=16;
float dmscatter=(log(fog_k(sun_theta_s))*rm_dx/MC_atom_height);
vec3 drscateer=vec3(-log(sun_atten_r)*rm_dx/MC_atom_height,-log(sun_atten_g)*rm_dx/MC_atom_height,-log(sun_atten_b)*rm_dx/MC_atom_height);
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

  //光路前面的所有光透过该微元的反应
  vec3 o_color=allcolor*scatterf(rm_dx/MC_atom_height);
  vec3 new_r_color=(allcolor-o_color)*orayleigh_phase;

o_color=o_color*(1-fog_kk(rm_dx/MC_atom_height,sun_theta_s));
  vec3 new_m_color=o_color*fog_kk(rm_dx/MC_atom_height,sun_theta_s)*omie_phase;
   vec3 new_color=new_r_color+new_m_color;
   allcolor=o_color;
  //太阳照亮的微元光
 float sun_to_rm_p = sunRayAtmLength(rm_p, sun_world);
 vec3 p_allcolor=vec3(0);
 {
//sun
//if(rm_sun_sign>0.5)
{
 vec3 p_suncolor=light_color*scatterf(sun_to_rm_p/MC_atom_height)*(1-fog_kk(sun_to_rm_p/MC_atom_height,sun_theta_s));;
   p_allcolor+=p_suncolor;
  vec3 p_light=pow(light.r,1)*blocklightColor;
  if(light.r<0.0355)p_light=vec3(0);
 if(depth==1.0)
 {
  p_suncolor*=sunCanReachPoint(rm_p, sun_world);
 }
 if(depth!=1.0)p_suncolor*=rm_sun_sign;
vec3 p_allcolor=p_suncolor+p_light;
 vec3 drcolor=p_allcolor*drscateer*rayleigh_phase;
 vec3 dmcolor=mie_phase*p_suncolor*dmscatter;
 vec3 dcolor=(dmcolor+drcolor);
 if(rm_sun_sign>0.5)dcolor*=shadow;
     allcolor+=dcolor;
}
      //moon
      //if(rm_sun_sign<0.5)
{
  float moon_to_rm_p = sunRayAtmLength(rm_p, -sun_world);
 vec3 p_mooncolor=moon_color*scatterf(moon_to_rm_p/MC_atom_height)*(1-fog_kk(moon_to_rm_p/MC_atom_height,sun_theta_s));
    p_allcolor+=p_mooncolor;
  if(depth==1.0)
 {
  p_mooncolor*=sunCanReachPoint(rm_p, -sun_world);
 }
 if(depth!=1.0)p_mooncolor*=(1-rm_sun_sign);
 vec3 drcolor=p_mooncolor*drscateer*moon_rayleigh_phase;
vec3 dmcolor=moon_mie_phase*p_mooncolor*dmscatter;
vec3  dcolor=(dmcolor+drcolor)*shadow;;
   allcolor+=dcolor;
}
       #if Side_Scatter == 1
if((i-1)%skyrefresht==0)
	     {
        p_skycolor=new_color;
				uint t=6; 
for(uint i=0;i<t;i++)
{
	vec3 p =HammersleySphereDir(i,t);
 vec3 tempcolor= skylightfogmodel(p, rm_p);
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
              vec3 g_color=p_allcolor*(dmscatter+drscateer)*pow(light.g,2);
              p_skycolor=g_color*(1.0/(4*PI));
   # endif
      allcolor+=p_skycolor;
 
  }
  //其他方向的天空光
	rm_p-=rm_v*rm_dx;
}
return  allcolor;
}
    float skyl(vec3 pixel_world,float pixel_r)
        {
          float pixel_world_theta_c=dot(pixel_world, vec3(0,1,0));
			float pixel_world_theta_s=sqrt(clamp(1- pixel_world_theta_c* pixel_world_theta_c,0,1));
          float l=1;
          float l_MP=1;
{
vec3 OP=vec3(0,pixel_r,0);
float tM=-dot(OP,pixel_world)+sqrt(pow(dot(OP,pixel_world),2)+pow(MC_ar,2)-pow(pixel_r,2));
l_MP=tM;
vec3 OM=OP+tM*pixel_world;
float tQ=-2*dot(OM,sun_world);
float l_r=l_MP;
if(tQ>=0)
{
vec3 OQ=OM+tQ*(sun_world);
vec3 OH=((OQ+OM)/2.0);
}
l=l_r/MC_atom_height;
}
   if(pixel_r>MC_ar)
   {
    l=0;
     if(pixel_world_theta_c<0&&pixel_world_theta_s<(MC_ar/pixel_r))
   {
    l=(2*sqrt(MC_ar*MC_ar-pixel_r*pixel_r*pixel_world_theta_s*pixel_world_theta_s))/MC_atom_height;
   }
   }
return l;
        }
     
float Vignette_G(float x, float y)
{
    float sx = sqrt(1.0 + x * x);
    float sy = sqrt(1.0 + y * y);

    return 0.5 * (
        x / sx * atan(y / sx) +
        y / sy * atan(x / sy)
    );
}
float Vignette_integralRect(vec3 fp, float a)
{
  float xc=fp.x;
  float yc=fp.y;
    float x1 = xc - a;
    float x2 = xc + a;
    float y1 = yc - a;
    float y2 = yc + a;

    return Vignette_G(x2, y2)
         - Vignette_G(x1, y2)
         - Vignette_G(x2, y1)
         + Vignette_G(x1, y1);
}
float  Vignette_classic(vec3 fp)
{
   float cosp=1.0/length(fp);
      float fk=pow(cosp,4.0);
      return fk;
}
   float pixel_r=(eyeAltitude-MC_sealevel)+MC_r;
   float sunl=skyl(sun_world,pixel_r);
      float center_depth=texture(depthtex0,vec2(0.5)).r;
   vec3 center_world= screenxyz_to_worldxyz(vec4(vec2(0.5),center_depth,1));
vec3 sune=scatterf(sunl)*(1-fog_kk(sunl,sun_theta_s));