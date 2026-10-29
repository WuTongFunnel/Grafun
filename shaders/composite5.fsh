#version 450 compatibility
#include "/lib/function.glsl"
uniform sampler3D atom;
in vec2 texcoord;
/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 finalcolor;

void main() {
      float alpha_g=texture(colortex8, texcoord).g;
        float alpha_r=texture(colortex8, texcoord).r;
    vec4 alpha_color = texture(colortex3, texcoord);
    vec4 color = texture(colortex0, texcoord);
        			#ifdef DISTANT_HORIZONS
if(gfDhFrontSky(texcoord))
#else
if(texture(depthtex0, texcoord).r==1.0)
#endif
	{
		return;
	}
  if (alpha_g > 0.5) {
        return;
    }
    if (alpha_r < 0.1&&wetness<0.01) {
        return;
    }
alpha_color.rgb = pow(alpha_color.rgb, vec3(2.2));
vec4 alpha_reflect_color=texture(colortex9, texcoord);
float alpha_t=texture(colortex8, texcoord).r;
    vec3 worldPos =texture(colortex15, texcoord).rgb;
#ifdef DISTANT_HORIZONS
// Reconstruct far positions from depth instead of quantized RGBA16F storage.
if (gfDhFrontAt(texcoord)) worldPos = gfDhPlayerPosition(texcoord, textureLod(dhDepthTex0, texcoord, 0.0).r);
#endif

    // ========== 3. 世界空间法线 ==========
         vec3 encodedNormal = texture(colortex5, texcoord).rgb;
    vec3 worldNormal = normalize((encodedNormal - 0.5) * 2.0);
       if (alpha_r < 0.1&&wetness>0.01) {
         encodedNormal = texture(colortex2, texcoord).rgb;
worldNormal = normalize((encodedNormal - 0.5) * 2.0);
    }

    #ifdef Realtime_Sky
		vec3 p = worldPos+cameraPosition;
vec3 worldup=vec3(0,1,0);

vec3 mcearthcore=gfEarthCenterWorld;
vec3 pcore=normalize(p-mcearthcore);
vec3 tempaxis = cross(worldup, pcore); 

float theta = acos( clamp(dot(worldup,pcore), -1.0, 1.0) );
vec3 paxis=normalize(tempaxis);
worldNormal=rotateVectorAroundAxis(worldNormal,paxis ,theta);
#endif
    // ========== 4. 世界空间视线和反射 ==========
    vec3 worldViewDir = normalize(worldPos);   // 从片元指向相机（在世界空间中，相机在原点）
    vec3 reflectDir = reflect(worldViewDir, worldNormal);
abs(reflectDir.y);
    // ========== 5. 调试：显示反射方向 ==========
    // finalcolor.rgb = reflectDir * 0.5 + 0.5;
    // return;

    // ========== 6. 世界空间光线步进 ==========
    vec3 reflectColor= vec3(0);
    	#ifndef Realtime_Sky 
//reflectColor=skybackground(vec3(reflectDir.x,abs(reflectDir.y),reflectDir.z),vec2(0),1,0).rgb+light_color*texture(atom,vec3(lut_texcoord(reflectDir,sun_world))).rgb+moon_color*texture(atom,vec3(lut_texcoord(reflectDir,-sun_world))).rgb;
#endif
   int maxSteps = SSR_MAX_STEPS;
    float stepSize = SSR_STEP_SIZE;           // 世界空间步长
    float thickness = SSR_THICKNESS;  
    float rayt=min(sqrt((1.0/(dot(reflectDir,worldNormal)*dot(reflectDir,worldNormal)))-1),512);     
    vec3 rayPos = worldPos + (rayt)* reflectDir;



    for (int i = 0; i < maxSteps; ++i) {

        // 世界空间 → 视图空间 → 投影到屏幕
        vec4 viewRayPos = gbufferModelView * vec4(rayPos, 1.0);
        viewRayPos.xyz /= viewRayPos.w;
        
        vec4 clipPos = gbufferProjection * vec4(viewRayPos.xyz, 1.0);
        clipPos.xyz /= clipPos.w;
        float rdepth=0.5*(clipPos.z)+0.5;
        vec2 sampleUV = clipPos.xy * 0.5 + 0.5;

        // 边界检查
        if (sampleUV.x < 0.0 || sampleUV.x > 1.0 ||
            sampleUV.y < 0.0 || sampleUV.y > 1.0) {
            break;
        }
     // 边界检查
        #ifdef DISTANT_HORIZONS
        // Continue past the native far plane while the ray is inside the DH
        // projection. Its screen XY uses the same camera/FOV.
        if (clipPos.w <= 0.0) break;
        if (clipPos.z>1||clipPos.z<-1) {
            vec4 distantClip = dhProjection * vec4(viewRayPos.xyz, 1.0);
            if (distantClip.w <= 0.0 || abs(distantClip.z / distantClip.w) > 1.0) break;
        }
#else
        if (clipPos.z>1||clipPos.z<-1) {
            break;
        }
#endif
        // 采样场景深度
        float sampleDepth = texture(depthtex0, sampleUV).r;
        vec4 sampleNDC = vec4(sampleUV * 2.0 - 1.0, sampleDepth * 2.0 - 1.0, 1.0);
        vec4 sampleViewPos = gbufferProjectionInverse * sampleNDC;
        sampleViewPos.xyz /= sampleViewPos.w;
#ifdef DISTANT_HORIZONS
        bool sampleIsDistant = gfDhFrontAt(sampleUV);
        if (sampleIsDistant) {
            float distantDepth = textureLod(dhDepthTex0, sampleUV, 0.0).r;
            sampleViewPos = vec4(gfDhViewPosition(sampleUV, distantDepth), 1.0);
        }
        // Past the native far plane only DH can supply an intersection. Do
        // not newly accept a near object that the original tracer clipped.
        if (!sampleIsDistant && clipPos.z > 1.0) {
            rayPos += stepSize * reflectDir;
            continue;
        }
#endif
        // 视图空间点构造齐次向量 w=1
vec4 sampleViewPos4 = vec4(sampleViewPos.xyz, 1.0);
// 乘逆ModelView，得到clip前的世界齐次坐标
vec4 sampleWorldPos4 = gbufferModelViewInverse * sampleViewPos4;
vec3 sampleWorldPos = sampleWorldPos4.xyz / sampleWorldPos4.w;

        #ifdef DISTANT_HORIZONS
        // Keep Grafun's existing native fallback. A DH sample is tested as
        // actual geometry below, even on the final step, never as a sun sprite.
        if(i==maxSteps-1 && !sampleIsDistant)
#else
        if(i==maxSteps-1)
#endif
    {  
       
        vec4 sunredercolor=texture(colortex11,sampleUV);
		if(sunredercolor.a>0.5)
			{
				reflectColor = texture(colortex0, sampleUV).rgb;

			}
     if(sampleDepth>0.9997&&sampleDepth<1)
        {
             reflectColor = texture(colortex0, sampleUV).rgb;
        }
            break;
    }
   #ifdef DISTANT_HORIZONS
   bool rayInFront = sampleIsDistant
       ? sampleViewPos.z < viewRayPos.z
       : sampleDepth > rdepth;
   if (rayInFront) {
#else
   if (sampleDepth> rdepth) {
#endif
    rayPos += stepSize * reflectDir;
         continue;
        }

        // 深度比较（视图空间）
        vec3  v=(sampleWorldPos.xyz-worldPos.xyz);
        float delta=dot(v,v) -dot(reflectDir,v)*dot(reflectDir,v);

        if (delta<pow(thickness,2)) {
            reflectColor = texture(colortex0, sampleUV).rgb;
            break;
        }

          rayPos += stepSize * reflectDir;
    }
float fresnel=pow(clamp(1-max(0,dot(-worldViewDir,worldNormal)),0.0,1.0),5);
    finalcolor.rgb= fresnel*reflectColor;
}

