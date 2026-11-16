#ifdef GRAFUN_VERTEX_STAGE
    #define GRAFUN_SHADOW_SAMPLE(sampler_name, uv) textureLod(sampler_name, uv, 0.0)
#else
    #define GRAFUN_SHADOW_SAMPLE(sampler_name, uv) texture(sampler_name, uv)
#endif

// Match native and DH shadow caster distortion, including at the shadow origin.
// Algebraically identical to the old mapping for r > 0, but without 0/0.
vec3 distortShadowClipPos(vec3 shadowClipPos){
  const float k = 0.95;
  float r = length(shadowClipPos.xy);
  shadowClipPos.xy /= (k * r + (1.0 - k));
  // Preserve Grafun's original low-sun depth coverage.
  shadowClipPos.z *= 0.025;
  return shadowClipPos;
}

vec3 getShadow(vec3 shadowScreenPos){
  // Outside the shadow-map volume is unshadowed, never sample a clamped border
  // texel and stretch its value over the distant terrain.
  if (any(lessThan(shadowScreenPos, vec3(0.0))) ||
      any(greaterThan(shadowScreenPos, vec3(1.0))))
    return vec3(1.0);

  float transparentShadow = step(shadowScreenPos.z,
      GRAFUN_SHADOW_SAMPLE(shadowtex0, shadowScreenPos.xy).r);
  if (transparentShadow == 1.0) return vec3(1.0);

  float opaqueShadow = step(shadowScreenPos.z,
      GRAFUN_SHADOW_SAMPLE(shadowtex1, shadowScreenPos.xy).r);
  if (opaqueShadow == 0.0) return vec3(0.0);

  vec4 shadowColor = GRAFUN_SHADOW_SAMPLE(shadowcolor0, shadowScreenPos.xy);
  shadowColor.rgb = pow(shadowColor.rgb, vec3(2.2));
  return shadowColor.rgb;
}

vec3 getSoftShadow(vec4 shadowClipPos, float bias){
  // Apply the clip-space bias before the same warp used by both caster passes.
  shadowClipPos.z -= bias;
  shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
  vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
  if (abs(shadowClipPos.w) < 1e-7 ||
      any(greaterThan(abs(shadowNDCPos), vec3(1.0))))
    return vec3(1.0);

  vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
  vec3 shadowAccum = vec3(0.0);
  const int samples = SHADOW_RANGE * SHADOW_RANGE * 4;

  // Filter *after* distortion, in actual shadow-map texels. This keeps
  // the PCF footprint uniform near and far and avoids warped sample jumps.
  for (int x = -SHADOW_RANGE; x < SHADOW_RANGE; ++x){
    for (int y = -SHADOW_RANGE; y < SHADOW_RANGE; ++y){
      vec2 sampleOffset = (vec2(x, y) + vec2(0.5)) *
          (SHADOW_RADIUS / (float(SHADOW_RANGE) * float(shadowMapResolution)));
      shadowAccum += getShadow(shadowScreenPos + vec3(sampleOffset, 0.0));
    }
  }
  return shadowAccum / float(samples);
}

#undef GRAFUN_SHADOW_SAMPLE
