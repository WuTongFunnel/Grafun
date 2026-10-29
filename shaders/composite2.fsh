
  //透明物体延迟渲染
#version 450 compatibility
#include "/lib/function.glsl"
uniform int renderStage;
uniform float nightVision;
in vec2 texcoord;
/*
const int colortex9Format = RGBA16F;
*/
/*
const int colortex0Format = RGBA16F;
*/
/*
const int colortex15Format = RGBA16F;
*/
/* RENDERTARGETS: 9,15 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 worldpos;
void main() {
  	color = texture(colortex3, texcoord);
worldpos=texture(colortex15, texcoord);
	color.rgb = pow(color.rgb, vec3(2.2));
	float depth = texture(depthtex0, texcoord).r;
		if(color.a<0.1)
{
	return;
}

			#ifdef DISTANT_HORIZONS
if(gfDhFrontSky(texcoord))
#else
if(depth==1.0)
#endif
	{
		return;
	}

//light

	vec2 light=texture(colortex4, texcoord).rg;
	vec3 encodedNormal = texture(colortex5, texcoord).rgb;
    vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
	 vec2 dtexcoord=texcoord;
	 #ifdef TAA
	 dtexcoord-=0.5*djlitter;
	 #endif
vec4 aNDC_Pos   = vec4(dtexcoord, depth, 1.0) * 2.0 - 1.0;
vec4 aviewPos   = gbufferProjectionInverse * aNDC_Pos;
aviewPos.xyz   /= aviewPos.w;
vec3 temp_pixel_world_pos = (gbufferModelViewInverse * aviewPos).xyz;
#ifdef DISTANT_HORIZONS
bool dhFront = gfDhFrontAt(texcoord);
if (dhFront) 
{
		float dhdepth=texture(dhDepthTex0,texcoord).r;
	 vec4 ndc = vec4(
            texcoord * 2.0 - 1.0 - djlitter,
            dhdepth * 2.0 - 1.0,
            1.0
        );
        vec4 viewPos =
            dhProjectionInverse * ndc;
        viewPos /= viewPos.w;
         temp_pixel_world_pos =
            (gbufferModelViewInverse * viewPos).xyz;
}
#endif
worldpos=vec4(temp_pixel_world_pos,1);
vec3 pixel_world=temp_pixel_world_pos+cameraPosition;
		vec3 p = pixel_world;
#ifdef Realtime_Sky
	vec3 worldup=vec3(0,1,0);
vec3 mcearthcore=gfEarthCenterWorld;
vec3 init_pcore=p-mcearthcore;
float pixel_r=length(init_pcore);
vec3 pcore=normalize(init_pcore);
vec3 tempaxis = cross(worldup, pcore); 

float theta = acos( clamp(dot(worldup,pcore), -1.0, 1.0) );
vec3 paxis=normalize(tempaxis);
normal=rotateVectorAroundAxis(normal,paxis ,theta);
#endif
	//阳光直射衰减系数
		vec3 sunlightColor=vec3(0) ;
vec3 moonlightcolor=vec3(0) ;
			vec3 skylightColor=vec3(0);
			#ifdef Realtime_Sky
			#ifdef Realtime_Skylight
		     {
				uint t=SKYLIGHT_LIVE_SAMPLES; 
for(uint i=0;i<t;i++)
{
	vec3 p =HammersleyCosHemisphereDir(i,t,normal);
 vec3 tempcolor= skylightfogmodel(p, temp_pixel_world_pos)+skybackground(p,vec2(0),1,1).rgb;

 skylightColor+=tempcolor;
}
skylightColor/=t;
skylightColor *=PI;  
      }
	  #endif  
#ifndef Realtime_Skylight
{
float x2 = normal.x*normal.x;
float y2 = normal.y*normal.y;
float z2 = normal.z*normal.z;

vec3 Lx = normal.x>0 ? texelFetch(colortex14, ivec2(1,0),0).rgb : texelFetch(colortex14, ivec2(1,1),0).rgb;
vec3 Ly = normal.y>0 ? texelFetch(colortex14, ivec2(0,0),0).rgb : texelFetch(colortex14, ivec2(0,1),0).rgb;
vec3 Lz = normal.z>0 ? texelFetch(colortex14, ivec2(2,0),0).rgb : texelFetch(colortex14, ivec2(2,1),0).rgb;

skylightColor = x2*Lx + y2*Ly + z2*Lz;

}
#endif
#ifdef Realtime_Sunlight
 float sunl=sunRayAtmLength(temp_pixel_world_pos, sun_world);   
				float moonl=sunRayAtmLength(temp_pixel_world_pos, -sun_world);
				moonlightcolor=moon_color*scatterf(moonl/MC_atom_height)*(1-fog_kk(moonl/MC_atom_height,sun_theta_s));
				sunlightColor = light_color*scatterf(sunl/MC_atom_height)*(1-fog_kk(sunl/MC_atom_height,sun_theta_s));
#endif
#ifndef Realtime_Sunlight
sunlightColor=texelFetch(colortex14, ivec2(3,1),0).rgb ;
moonlightcolor=texelFetch(colortex14, ivec2(3,2),0).rgb;
#endif
#endif

#ifndef Realtime_Sky
float x2 = normal.x*normal.x;
float y2 = normal.y*normal.y;
float z2 = normal.z*normal.z;

vec3 Lx = normal.x>0 ? texelFetch(colortex14, ivec2(1,0),0).rgb : texelFetch(colortex14, ivec2(1,1),0).rgb;
vec3 Ly = normal.y>0 ? texelFetch(colortex14, ivec2(0,0),0).rgb : texelFetch(colortex14, ivec2(0,1),0).rgb;
vec3 Lz = normal.z>0 ? texelFetch(colortex14, ivec2(2,0),0).rgb : texelFetch(colortex14, ivec2(2,1),0).rgb;

skylightColor = x2*Lx + y2*Ly + z2*Lz;
sunlightColor=texelFetch(colortex14, ivec2(3,1),0).rgb ;
moonlightcolor=texelFetch(colortex14, ivec2(3,2),0).rgb;
#endif
//散射系数 
//shadow
vec3 shadow=vec3(0);
{
vec3 feetPlayerPos = temp_pixel_world_pos;
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
#ifdef DISTANT_HORIZONS
if (dhFront) shadow = gfDhReceiveShadow(shadowClipPos, temp_pixel_world_pos, 0.001);
else
#endif
shadow= getSoftShadow(shadowClipPos,0.005); 
}
//light
float realsky=pow(light.g,2);
if(realsky<0.00125321875)realsky=0.000004;
float reallight=pow(light.r,2);
reallight=smoothstep(0,1,reallight)*reallight;
	vec3 skylight=(skylightColor)*realsky;
#if SKYLIGHT_STRENGTH != 100
    skylight *= float(SKYLIGHT_STRENGTH) / 100.0;
#endif//加上星空光
	vec3 blocklight =reallight * blocklightColor;
	float sun_sign=1;
	if(sun_theta_c<0)sun_sign=0;
vec3 sunlight = sun_sign*sunlightColor * clamp(dot( sun_world, normal), 0.0, 1.0)*shadow;
vec3 moonlight =  moonlightcolor* clamp(dot( -sun_world, normal), 0.0, 1.0)*shadow;
if(texture(colortex5, texcoord).a>1)
{
	sunlight = sun_sign*sunlightColor *shadow;
moonlight =  moonlightcolor*shadow;
}
vec3 ambient=realsky*max(dot(normal,vec3(0,-1,0)),0)*(vec3(TRANSLUCENT_AMBIENT_COEFFICIENT)*clamp(dot(sun_world,vec3(0,1,0)),0,1)*(sunlightColor/light_color)+moonk*vec3(TRANSLUCENT_AMBIENT_COEFFICIENT)*clamp(dot(-sun_world,vec3(0,1,0)),0,1));
vec3 E_light=gfHandLight;
vec3 q=vec3(0,0,0);
vec3 right_hand_light=(E_light/(length(temp_pixel_world_pos-q)*length(temp_pixel_world_pos-q)))*clamp(dot(-normalize(temp_pixel_world_pos-q),normal),0,1);
vec3 finallight=skylight+ blocklight+sunlight+ambient+moonlight+right_hand_light;
color.rgb *=(finallight/PI);
}