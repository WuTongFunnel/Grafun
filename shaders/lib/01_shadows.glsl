#ifdef GRAFUN_VERTEX_STAGE
    #define GRAFUN_SHADOW_SAMPLE(sampler_name, uv) textureLod(sampler_name, uv, 0.0)
#else
    #define GRAFUN_SHADOW_SAMPLE(sampler_name, uv) texture(sampler_name, uv)
#endif

vec3 distortShadowClipPos(vec3 shadowClipPos){
  float k=0.95;
  float distortionFactor = 1/(k+(1/(length(shadowClipPos.xy)))*(1-k)); // distance from the player in shadow clip space

  shadowClipPos.xy /= length(shadowClipPos.xy);
    shadowClipPos.xy*=distortionFactor;
  shadowClipPos.z *= 0.125; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky

  return shadowClipPos;
}
vec3 getShadow(vec3 shadowScreenPos){
  float transparentShadow = step(shadowScreenPos.z, GRAFUN_SHADOW_SAMPLE(shadowtex0, shadowScreenPos.xy).r); // sample the shadow map containing everything
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

  float opaqueShadow = step(shadowScreenPos.z, GRAFUN_SHADOW_SAMPLE(shadowtex1, shadowScreenPos.xy).r); // sample the shadow map containing only opaque stuff

  if(opaqueShadow == 0.0){
    // there is a shadow cast by something opaque, so we return no sunlight
    return vec3(0.0);
  }

  // contains the color and alpha (transparency) of the thing casting a shadow
  vec4 shadowColor = GRAFUN_SHADOW_SAMPLE(shadowcolor0, shadowScreenPos.xy);
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
offsetShadowClipPos.z -= bias * offsetShadowClipPos.w;
   offsetShadowClipPos.z-=0.05*length(offsetShadowClipPos.xy);
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadowAccum += getShadow(shadowScreenPos); // take shadow sample
    }
  }

  return shadowAccum / float(samples); // divide sum by count, getting average shadow
}

#undef GRAFUN_SHADOW_SAMPLE
