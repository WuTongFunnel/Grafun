#version 450 compatibility
#include /lib/function.glsl
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex10;
in vec2 texcoord;
const bool colortex0MipmapEnabled = true;
/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 finalcolor;

void main() {
      float alpha_g=texture(colortex8, texcoord).g;
    vec4 alpha_color = texture(colortex3, texcoord);
    vec4 color = texture(colortex0, texcoord);
  if (alpha_g > 0.5) {
        return;
    }
    if (alpha_color.a < 0.001) {
        return;
    }
alpha_color.rgb = pow(alpha_color.rgb, vec3(2.2));
vec4 alpha_reflect_color=texture(colortex9, texcoord);
float alpha_t=texture(colortex8, texcoord).r;

    // ========== 1. 获取视图空间位置 ==========
    vec4 ndcPos = vec4(texcoord, texture(depthtex0, texcoord).r, 1.0);
    ndcPos.xyz = ndcPos.xyz * 2.0 - 1.0;
    vec4 viewPosRaw = gbufferProjectionInverse * ndcPos;
    viewPosRaw.xyz /= viewPosRaw.w;
    vec3 viewPos = viewPosRaw.xyz;

    // ========== 2. 视图空间 → 世界空间 ==========
    vec4 worldPos4 = gbufferModelViewInverse * vec4(viewPos, 1.0);
    vec3 worldPos = worldPos4.xyz / worldPos4.w;

    // ========== 3. 世界空间法线 ==========
    vec3 encodedNormal = texture(colortex5, texcoord).rgb;
    vec3 worldNormal = normalize((encodedNormal - 0.5) * 2.0);
		vec3 p = worldPos+cameraPosition;
vec3 worldup=vec3(0,1,0);

vec3 mcearthcore=vec3(cameraPosition.x,MC_sealevel-MC_r,cameraPosition.z);
vec3 pcore=normalize(p-mcearthcore);
vec3 tempaxis = cross(worldup, pcore); 

float theta = acos( clamp(dot(worldup,pcore), -1.0, 1.0) );
vec3 paxis=normalize(tempaxis);
worldNormal=rotateVectorAroundAxis(worldNormal,paxis ,theta);

    // ========== 4. 世界空间视线和反射 ==========
    vec3 worldViewDir = normalize(worldPos);   // 从片元指向相机（在世界空间中，相机在原点）
    vec3 reflectDir = reflect(worldViewDir, worldNormal);

    // ========== 5. 调试：显示反射方向 ==========
    // finalcolor.rgb = reflectDir * 0.5 + 0.5;
    // return;

    // ========== 6. 世界空间光线步进 ==========
    vec3 reflectColor = reflect_sky(reflectDir,p.y).rgb*pow(texture(colortex4,texcoord).g,2);
   int maxSteps = 512;
    float stepSize = 0.5;           // 世界空间步长
    float thickness = 0.5;           // 厚度阈值
    vec3 rayPos = worldPos + 0.5* reflectDir;


    bool hit = false;

    for (int i = 0; i < maxSteps; ++i) {
        rayPos += stepSize * reflectDir;

        // 世界空间 → 视图空间 → 投影到屏幕
        vec4 viewRayPos = gbufferModelView * vec4(rayPos, 1.0);
        viewRayPos.xyz /= viewRayPos.w;
        
        vec4 clipPos = gbufferProjection * vec4(viewRayPos.xyz, 1.0);
        clipPos.xyz /= clipPos.w;
        vec2 sampleUV = clipPos.xy * 0.5 + 0.5;

        // 边界检查
        if (sampleUV.x < 0.0 || sampleUV.x > 1.0 ||
            sampleUV.y < 0.0 || sampleUV.y > 1.0) {
            break;
        }

        // 采样场景深度
        float sampleDepth = texture(depthtex0, sampleUV).r;
        vec4 sampleNDC = vec4(sampleUV * 2.0 - 1.0, sampleDepth * 2.0 - 1.0, 1.0);
        vec4 sampleViewPos = gbufferProjectionInverse * sampleNDC;
        sampleViewPos.xyz /= sampleViewPos.w;

        // 深度比较（视图空间）
        float rayDepth = -viewRayPos.z;
        float sceneDepth = -sampleViewPos.z;
        float delta = rayDepth - sceneDepth;

        if (delta > 0.0 &&delta<thickness) {
            hit = true;
            reflectColor = texture(colortex0, sampleUV).rgb;
            break;
        }
        if(i==maxSteps-1)
    {
        vec4 sunredercolor=texture(colortex11,sampleUV);
		if(sunredercolor.a>0.5)
			{
				reflectColor = texture(colortex0, sampleUV).rgb;
			}
    }
     
    }

    finalcolor.rgb= reflectColor;
}