#ifndef GRAFUN_WATER_SURFACE_GLSL
#define GRAFUN_WATER_SURFACE_GLSL

// Clean dielectric water. 0 absorption means fully clear transmission.
// Water is flagged by colortex8.b. No diffuse light is added.
#define WATER_WAVE_STRENGTH 60 // [0 20 40 60 80 100]
#define WATER_WAVE_SPEED 70 // [0 25 50 70 100 150 200]
#define WATER_WAVE_SCALE 50 // [0 25 50 75 100]
#define WATER_REFRACTION 65 // [0 25 50 65 80 100]
#define WATER_ABSORPTION 0 // [0 5 10 20 40 60 100]
#define WATER_SHORE_FOAM 0 // [0 25 50 75 100]

const float GRAFUN_WATER_F0 = 0.020373;  // ((1.0-1.333)/(1.0+1.333))^2

float grafunWaterFresnel(float cosTheta)
{
    float x = 1.0 - clamp(cosTheta, 0.0, 1.0);
    return GRAFUN_WATER_F0 + (1.0-GRAFUN_WATER_F0) * x*x*x*x*x;
}

// Smooth animated wave slope; evaluating at absolute XZ makes adjacent
// pixels and near/far water use the same field, without a normal texture.
vec2 grafunWaterSlope(vec2 absoluteXZ)
{
    float scale = mix(0.65, 1.55, float(WATER_WAVE_SCALE) / 100.0);
    float speed = float(WATER_WAVE_SPEED) / 100.0;
    float t = mod(frameTimeCounter, 4096.0) * speed;
    vec2 p = absoluteXZ * scale;

    vec2 d0 = normalize(vec2( 0.89,  0.45));
    vec2 d1 = normalize(vec2(-0.52,  0.85));
    vec2 d2 = normalize(vec2( 0.97, -0.24));
    vec2 d3 = normalize(vec2( 0.27,  0.96));

    float a0 = dot(p, d0) * 0.31 + t * 0.92;
    float a1 = dot(p, d1) * 0.48 + t * 1.33;
    float a2 = dot(p, d2) * 0.71 - t * 1.76;
    float a3 = dot(p, d3) * 1.11 + t * 2.38;

    vec2 slope = d0 * (0.18 * 0.31 * cos(a0))
               + d1 * (0.09 * 0.48 * cos(a1))
               + d2 * (0.045 * 0.71 * cos(a2))
               + d3 * (0.018 * 1.11 * cos(a3));
    return slope * scale * (float(WATER_WAVE_STRENGTH) / 60.0);
}

vec3 grafunWaterNormal(vec3 geometricNormal, vec3 cameraRelativePos)
{
    vec3 n = normalize(geometricNormal);
    // Keep waterfall sides and steep faces geometrically stable.
    float surfaceWeight = smoothstep(0.35, 0.85, abs(n.y));
    if (surfaceWeight <= 0.001 || WATER_WAVE_STRENGTH == 0)
        return n;

    vec3 tangentX = vec3(1.0, 0.0, 0.0) - n * n.x;
    if (dot(tangentX, tangentX) < 1e-5)
        tangentX = vec3(0.0, 0.0, 1.0) - n * n.z;
    tangentX = normalize(tangentX);
    vec3 tangentZ = normalize(cross(tangentX, n));

    vec2 slope = grafunWaterSlope(cameraRelativePos.xz + cameraPosition.xz);
    // Dampen subpixel wave aliasing in the far field.
    float farFade = 1.0 / (1.0 + length(cameraRelativePos) * 0.0010);
    return normalize(n - surfaceWeight * farFade *
            (slope.x * tangentX + slope.y * tangentZ));
}

// Distance from the top water plane to the opaque scene along the view ray.
// This is an approximation used only for subtle distortion and optional tint.
float grafunWaterDepth(vec2 uv, vec3 waterPos)
{
    vec3 behind = vec3(0.0);
#ifdef DISTANT_HORIZONS
    if (gfDhOpaqueAt(uv))
    {
        float dhD = textureLod(dhDepthTex1, uv, 0.0).r;
        if (dhD >= 0.999999) return 32.0;
        behind = gfDhPlayerPosition(uv, dhD);
    }
    else
#endif
    {
        float d = texture(depthtex1, uv).r;
        if (d >= 0.999999) return 32.0;
        vec4 h = gbufferProjectionInverse * vec4(uv*2.0-1.0, d*2.0-1.0, 1.0);
        if (abs(h.w) < 1e-7) return 0.0;
        behind = (gbufferModelViewInverse * vec4(h.xyz/h.w, 1.0)).xyz;
    }
    return max(0.0, length(behind) - length(waterPos));
}

// Uses screen-color background that has ALREADY been independently shaded
// and atmospherically composited. Never recomputes atmosphere here.
vec2 grafunWaterRefractionUV(vec2 uv, vec3 waterPos,
                             vec3 baseNormal, vec3 waveNormal,
                             float depthBehind)
{
    if (WATER_REFRACTION == 0) return uv;
    vec3 waveDeltaVS = mat3(gbufferModelView) * (waveNormal - baseNormal);
    float scale = float(WATER_REFRACTION) / 100.0;
    float depthFactor = sqrt(clamp(depthBehind / 5.0, 0.0, 1.0));
    vec2 pixelOffset = waveDeltaVS.xy * (18.0 * scale * depthFactor);
    // Strong distortion at silhouettes looks like screen-space bleeding.
    vec2 candidate = uv + pixelOffset / vec2(viewWidth, viewHeight);
    if (any(lessThan(candidate, vec2(0.001))) ||
        any(greaterThan(candidate, vec2(0.999)))) return uv;

    // The new background sample must remain behind the original water surface.
    // Otherwise keep the original UV to avoid foreground-object ghosting.
    float sampleDepth = grafunWaterDepth(candidate, waterPos);
    if (sampleDepth < 0.08) return uv;
    return candidate;
}

vec3 grafunWaterTransmission(vec3 background, float depthBehind)
{
#if WATER_ABSORPTION > 0
    float absorption = (float(WATER_ABSORPTION) / 100.0) * 0.07;
    vec3 sigma = vec3(1.8, 0.55, 0.18) * absorption;
    return background * exp(-sigma * clamp(depthBehind, 0.0, 80.0));
#else
    return background;  // Default: perfectly clear, no diffuse/albedo tint
#endif
}

// Optional shoreline foam; OFF by default because it is not a dielectric
// reflection and the requested water has no diffuse component.
vec3 grafunWaterFoam(vec3 color, float thickness, vec3 worldPos)
{
#if WATER_SHORE_FOAM > 0
    float edge = 1.0 - smoothstep(0.05, 0.9, thickness);
    float noise = 0.5 + 0.5 * sin(worldPos.x*3.7 + worldPos.z*4.9 + frameTimeCounter*2.7);
    float amount = edge * smoothstep(0.25, 0.8, noise) *
                   (float(WATER_SHORE_FOAM) / 100.0) * 0.3;
    return mix(color, vec3(0.7), amount);
#else
    return color;
#endif
}

#endif // GRAFUN_WATER_SURFACE_GLSL
