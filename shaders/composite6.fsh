#version 450 compatibility
#include "/lib/function.glsl"
#include "/lib/13_water_surface.glsl"
in vec2 texcoord;
/* RENDERTARGETS: 0,7 */
layout(location = 0) out vec4 finalcolor;
layout(location = 1) out vec4 Lcolor;
void main() {
vec3 hdr = max(texture(colortex0, texcoord).rgb, vec3(0.0));

float luminance = (E(hdr));
 if(luminance<1e-10) luminance=1e-10;
Lcolor = vec4(log2(luminance), 0.0, 0.0, 1.0);

    float alpha_g=texture(colortex8, texcoord).g;
     finalcolor = texture(colortex0, texcoord);
            			#ifdef DISTANT_HORIZONS
if(gfDhFrontSky(texcoord))
#else
if(texture(depthtex0, texcoord).r==1.0)
#endif
	{
		return;
	}
          float alpha_t=texture(colortex8, texcoord).r;
          bool isWater = texture(colortex8, texcoord).b > 0.5;
          if (isWater)
          {
              // Reflection is already premultiplied by the Fresnel coefficient
              // in composite5. The water has NO diffuse term.
              vec3 worldPos = texture(colortex15, texcoord).rgb;
#ifdef DISTANT_HORIZONS
              if (gfDhFrontAt(texcoord))
              {
                  float d = textureLod(dhDepthTex0, texcoord, 0.0).r;
                  worldPos = gfDhPlayerPosition(texcoord, d);
              }
#endif
              vec3 baseNormal = normalize(texture(colortex5, texcoord).rgb * 2.0 - 1.0);
#ifdef Realtime_Sky
              vec3 p = worldPos + cameraPosition;
              vec3 up = vec3(0.0, 1.0, 0.0);
              vec3 surfaceUp = normalize(p - gfEarthCenterWorld);
              vec3 axis = cross(up, surfaceUp);
              if (dot(axis, axis) > 1e-12)
                  baseNormal = rotateVectorAroundAxis(baseNormal,
                       normalize(axis), acos(clamp(dot(up, surfaceUp),-1.0,1.0)));
#endif
              if (dot(worldPos, worldPos) > 1e-8 &&
                  dot(-normalize(worldPos), baseNormal) < 0.0)
                  baseNormal = -baseNormal;
              vec3 waveNormal = grafunWaterNormal(baseNormal, worldPos);
              float waterDepth = grafunWaterDepth(texcoord, worldPos);
              vec2 refractUV = grafunWaterRefractionUV(
                  texcoord, worldPos, baseNormal, waveNormal, waterDepth);
              vec3 transmission = texture(colortex0, refractUV).rgb;
              transmission = grafunWaterTransmission(transmission, waterDepth);

              vec4 reflectResult = texture(colortex12, texcoord);
              float F = clamp(reflectResult.a, 0.0, 1.0);
              vec3 combined = transmission * (1.0 - F) + reflectResult.rgb;
              // Foam is optional and disabled by default.
              finalcolor.rgb = grafunWaterFoam(combined, waterDepth, worldPos);
              // Update exposure statistics for the actual water result.
              float waterL = max(E(max(finalcolor.rgb, vec3(0.0))), 1e-10);
              Lcolor = vec4(log2(waterL), 0.0, 0.0, 1.0);
              return;
          }
          if (alpha_g > 0.5) {
        return;
    }
      if (!isWater && alpha_t < 0.001&&wetness<0.01) {
        return;
    }
        vec3 alpha_color = texture(colortex3, texcoord).rgb;
 float dx = gfPixelSize.x;
float dy = gfPixelSize.y;
float range = REFLECTION_BLUR;   // 采样半径，单位：像素

vec4 testcolor = vec4(0.0);
float count = 0.0;

// y轴范围，围绕当前texcoord.y
float yMin = max(texcoord.y - range * dy, 0.0);
float yMax = min(texcoord.y + range * dy, 1.0);

// x轴范围，围绕当前texcoord.x
float xMin = max(texcoord.x - range * dx, 0.0);
float xMax = min(texcoord.x + range * dx, 1.0);

for(float i = yMin; i <= yMax; i += dy)
{
    for(float j = xMin; j <= xMax; j += dx)
    {
        // Water must not blur in neighboring glass/terrain SSR pixels.
        if (!isWater || texture(colortex8, vec2(j, i)).b > 0.5)
        {
            testcolor += texture(colortex12, vec2(j, i));
            count += 1.0;
        }
    }
}
vec4 avgColor = testcolor / max(count, 1.0);
vec3 reflect_color=avgColor.rgb;
#if REFLECTION_STRENGTH != 100
    reflect_color *= isWater ? min(float(REFLECTION_STRENGTH) / 100.0, 1.0) : float(REFLECTION_STRENGTH) / 100.0;
#endif
 if (alpha_t < 0.001&&wetness>0.01) {
    finalcolor.rgb+=wetness*reflect_color;
        return;
    }
finalcolor.rgb+=reflect_color;

}