#include "/lib/setting.glsl"
const float shadowDistance = 512;
// defines the total radius in which we sample (in pixels)
#define SHADOW_RADIUS 2
// controls how many samples we take for every pixel we sample
#define SHADOW_RANGE  6
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
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
float mkt=1;
float mie_g = 0.375;
float fog_kk(float l2, float sun_theta_s)
{
     float fog_world_fun_max=1.15;
			float fog_world_fun_min=1.025;
			float fog_world_fun_speed=4;
			float fog_world_fun=(fog_world_fun_max-fog_world_fun_min)*pow(sun_theta_s,2*fog_world_fun_speed)+fog_world_fun_min;
 float mix_sky_k=1-pow(fog_world_fun,-l2);
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


  /*
  we use 1 - the alpha to get how much light is let through
  and multiply that light by the color of the caster
  */
  return shadowColor.rgb * (1.0 - shadowColor.a);
}
vec3 getSoftShadow(vec4 shadowClipPos,float depth){
  vec3 shadowAccum = vec3(0.0); // sum of all shadow samples
  const int samples = SHADOW_RANGE * SHADOW_RANGE * 4; // we are taking 2 * SHADOW_RANGE * 2 * SHADOW_RANGE samples

  for(int x = -SHADOW_RANGE; x < SHADOW_RANGE; x++){
    for(int y = -SHADOW_RANGE; y < SHADOW_RANGE; y++){
      vec2 offset = vec2(x, y) * SHADOW_RADIUS / float(SHADOW_RANGE);
      offset /= shadowMapResolution; // offset in the rotated direction by the specified amount. We divide by the resolution so our offset is in terms of pixels
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.z -= 0.000075*(depth+6.25); // apply bias
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
uniform sampler2D colortex14;
uniform vec3 sun_origin_base_color;
uniform vec3 light_pollution_color;
uniform float eyeAltitude;
uniform sampler2D colortex11;
float atom_height=100000;
float earth_factor=500;
float earth_r=6371000;
float MC_r=(earth_r/earth_factor);
float MC_atom_height=(atom_height/earth_factor);
float MC_ar=MC_r+ MC_atom_height;
float MC_sealevel=65;
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
     vec3 raw_mie_color(float l,vec3 sun_color)
       {
        float fog_world_k=fog_kk(l,  sun_theta_s);
					vec3 fog_color=sun_color;
float fog_k=0.987* fog_world_k;
vec3 fog_light_color=fog_color*fog_k;
return fog_light_color;
       }
        vec3 scatterf(float l)
        {
         return vec3(pow(mkt*sun_atten_r,pow(l,kt)),pow(mkt*sun_atten_g,pow(l,kt)),pow(mkt*sun_atten_b,pow(l,kt)));
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

       vec4 skybackground(vec3 pixel_world,float l,vec2 texcoord,float depth,vec3 scatter_vector)
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
if(pixel_world_theta_c>0)
{
float unref_a=-0.0009375;
float unref_true_theta= unref_false_theta+(unref_a/(unref_false_theta+(unref_a/radians(-0.6))));

vec2 unref_temp=normalize(vec2(pixel_world.x,pixel_world.z));
 unref_pixel_world=normalize(vec3(unref_temp.r,tan(unref_true_theta),unref_temp.g));
}
if(l<0.0001)unref_pixel_world=pixel_world;
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
vec3 starcolor = texture(colortex14, uv).rgb;
if(depth==1.0)
{
color.rgb=0.002 * starcolor;
	//太阳渲染
  vec4 sunredercolor=texture(colortex11,texcoord);
		if(sunredercolor.a>0.5)
			{
				color.rgb=sunredercolor.rgb;
			}
}
color.rgb *=scatter_vector;
color.rgb-=(1-3/(8*PI))*raw_mie_color(l,color.rgb);

return color;
       }
       vec3 raw_rayleigh_color(vec3 sun_base_color,vec3 sun_color )
       {
        	vec3 skycolor =(sun_base_color-sun_color);
				skycolor.g*=0.4;
        return skycolor;

       }
vec4 sky(vec2 texcoord,float depth)
{
 vec4 color=vec4(0,0,0,1);
vec3 pixel_world=screenxyz_to_worldxyz(vec4(texcoord,depth,1));
    
		float pixel_world_theta_c=dot(pixel_world, vec3(0,1,0));
			float pixel_world_theta_s=sqrt(clamp(1- pixel_world_theta_c* pixel_world_theta_c,0,1));
   float pixel_r=(eyeAltitude-MC_sealevel)+MC_r;

  	float sunlight_k=1;
if(sun_theta_c<0)sunlight_k=pow(clamp(sun_theta_s,0,1),50);
vec3 sun_base_color=sun_origin_base_color*sunlight_k;

 float l=skyl(pixel_world,pixel_r);
vec3 scatter_vector=scatterf(l);
color+=skybackground(pixel_world, l,texcoord, depth,scatter_vector);

	vec3 sun_color=(sun_base_color)*scatter_vector;
			float pixel_sun_theta_c=dot(pixel_world,sun_world);
      float rayleigh_phase=(3/(16*PI))*(1+pixel_sun_theta_c*pixel_sun_theta_c);
      vec3 rcolor=raw_rayleigh_color(sun_base_color,sun_color );
      color.rgb+=rayleigh_phase*rcolor;
			//天空渲染
			//体积光照
//阳光米氏散射雾
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*pixel_sun_theta_c, 1.5);
vec3 m_color=raw_mie_color(l,sun_color)*mie_phase;
					color.rgb+=m_color;
return color;
}
vec4 reflect_sky(vec3 pixel_world,float pixely)
{
 vec4 color=vec4(0,0,0,1);
    
		float pixel_world_theta_c=dot(pixel_world, vec3(0,1,0));
			float pixel_world_theta_s=sqrt(clamp(1- pixel_world_theta_c* pixel_world_theta_c,0,1));
   float pixel_r=(pixely-MC_sealevel)+MC_r;

  	float sunlight_k=1;
if(sun_theta_c<0)sunlight_k=pow(clamp(sun_theta_s,0,1),50);
vec3 sun_base_color=sun_origin_base_color*sunlight_k;

 float l=skyl(pixel_world,pixel_r);
vec3 scatter_vector=scatterf(l);
color+=skybackground(pixel_world, l,vec2(0,0), 1,scatter_vector);

	vec3 sun_color=(sun_base_color)*scatter_vector;
			float pixel_sun_theta_c=dot(pixel_world,sun_world);
      float rayleigh_phase=(3/(16*PI))*(1+pixel_sun_theta_c*pixel_sun_theta_c);
      vec3 rcolor=raw_rayleigh_color(sun_base_color,sun_color);
      color.rgb+=rayleigh_phase*rcolor;
			//天空渲染
			//体积光照
//阳光米氏散射雾
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*pixel_sun_theta_c, 1.5);
vec3 m_color=raw_mie_color(l,sun_color)*mie_phase;
					color.rgb+=m_color;

return color;
}

vec3 fogmodel(float l,vec3 sun_base_color,float pixel_sun_theta_c)
{
 vec3 color=vec3(0);
    
vec3 scatter_vector=scatterf(l);

	vec3 sun_color=(sun_base_color)*scatter_vector;
        float rayleigh_phase=(3/(16*PI))*(1+pixel_sun_theta_c*pixel_sun_theta_c);
      vec3 rcolor=raw_rayleigh_color(sun_base_color,sun_color )* rayleigh_phase;
      color.rgb+=rcolor;
float mie_phase = (1.0 / (4.0 * PI)) * (1.0 - mie_g*mie_g) / pow(1.0 + mie_g*mie_g - 2.0*mie_g*pixel_sun_theta_c, 1.5);

vec3 m_color=raw_mie_color(l,sun_color)*mie_phase;
					color.rgb+=m_color;
return color;
}