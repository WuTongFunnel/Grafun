
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
		float ao=color.a*color.a;
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
// Direct solar and lunar lighting, without sky irradiance.
#ifdef Realtime_Sunlight
vec3 sunlightColor = light_color * onlyafterT(temp_pixel_world_pos, sun_world);
vec3 moonlightcolor = moon_color* onlyafterT(temp_pixel_world_pos, -sun_world);;
#else
vec3 sunlightColor = texelFetch(colortex14, ivec2(3,1), 0).rgb;
vec3 moonlightcolor = texelFetch(colortex14, ivec2(3,2), 0).rgb;
#endif
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
float reallight=pow(light.r,2);
reallight=smoothstep(0,1,reallight)*reallight;
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
vec3 E_light=gfHandLight;
vec3 q=vec3(0,0,0);
vec3 right_hand_light=(E_light/(length(temp_pixel_world_pos-q)*length(temp_pixel_world_pos-q)))*clamp(dot(-normalize(temp_pixel_world_pos-q),normal),0,1);
vec3 skylightColor = vec3(0.0);
#ifdef Realtime_Skylight
uint t = uint(SKYLIGHT_LIVE_SAMPLES);
for (uint i = 0u; i < t; ++i)
{
    vec3 skyDir = HammersleyCosHemisphereDir(i, t, normal);
    if (skyDir.y < 0.0) continue;
    skylightColor += subAtomfog(vec3(0.0), vec3(0.0), skyDir, 1.0);
}
skylightColor *= PI / float(t);
#else
vec3 Lx = normal.x > 0.0 ? texelFetch(colortex14, ivec2(1,0),0).rgb : texelFetch(colortex14, ivec2(1,1),0).rgb;
vec3 Ly = normal.y > 0.0 ? texelFetch(colortex14, ivec2(0,0),0).rgb : texelFetch(colortex14, ivec2(0,1),0).rgb;
vec3 Lz = normal.z > 0.0 ? texelFetch(colortex14, ivec2(2,0),0).rgb : texelFetch(colortex14, ivec2(2,1),0).rgb;
skylightColor = abs(normal.x) * Lx + abs(normal.y) * Ly + abs(normal.z) * Lz;
#endif
float realsky=pow(light.g,2);
	vec3 skylight=(skylightColor)*realsky;
	vec3 ambient=realsky*clamp(dot(normal,vec3(0,-1,0)),0,1)*realsky*vec3(AMBIENT_COEFFICIENT)*(clamp(dot(sun_world,vec3(0,1,0)),0,1)*sunlightColor+moonlightcolor*clamp(dot(-sun_world,vec3(0,1,0)),0,1));
vec3 finallight=blocklight+sunlight+moonlight+right_hand_light+skylight*ao+ambient+ambient*(1-ao);
color.rgb *=(finallight/PI);

}