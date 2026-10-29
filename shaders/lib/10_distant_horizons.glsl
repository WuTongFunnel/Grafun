#ifndef GRAFUN_DISTANT_HORIZONS_GLSL
#define GRAFUN_DISTANT_HORIZONS_GLSL

// The entire extension is excluded from the original non-DH programs.
#ifdef DISTANT_HORIZONS
uniform sampler2D dhDepthTex0;
uniform mat4 dhProjection;
uniform mat4 dhProjectionInverse;

// dhDepthTex1 is already declared in 00_globals_and_fog_coefficients.glsl.
// Native and DH depth have DIFFERENT near/far planes. Never compare their raw
// values or unproject DH depth with gbufferProjectionInverse.
vec3 gfDhViewPosition(vec2 uv, float depth)
{
    vec4 p = dhProjectionInverse * vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    return p.xyz / p.w;
}

vec3 gfDhPlayerPosition(vec2 uv, float depth)
{
    return (gbufferModelViewInverse * vec4(gfDhViewPosition(uv, depth), 1.0)).xyz;
}

float gfNativeViewZ(vec2 uv, float depth)
{
    vec4 p = gbufferProjectionInverse * vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    return p.z / p.w;
}

bool gfDhOpaqueAt(vec2 uv)
{
    // Native opaque geometry renders AFTER DH terrain and owns this G-buffer.
    return textureLod(depthtex1, uv, 0.0).r == 1.0
        && textureLod(dhDepthTex1, uv, 0.0).r < 1.0;
}

bool gfDhFrontAt(vec2 uv)
{
    float native0 = textureLod(depthtex0, uv, 0.0).r;
    float native1 = textureLod(depthtex1, uv, 0.0).r;
    float distant0 = textureLod(dhDepthTex0, uv, 0.0).r;
    // Native translucents render AFTER DH water and own the front metadata.
    if (native0 != native1 || distant0 == 1.0) return false;
    if (native0 == 1.0) return true;
    float distant1 = textureLod(dhDepthTex1, uv, 0.0).r;
    if (distant0 == distant1) return false;
    // A DH translucent can be in front of native opaque geometry. Larger
    // (less negative) view-space Z means closer, regardless of projection.
    return gfDhViewPosition(uv, distant0).z > gfNativeViewZ(uv, native0);
}

bool gfDhOpaqueSky(vec2 uv)
{
    return textureLod(depthtex1, uv, 0.0).r == 1.0
        && textureLod(dhDepthTex1, uv, 0.0).r == 1.0;
}

bool gfDhFrontSky(vec2 uv)
{
    return textureLod(depthtex0, uv, 0.0).r == 1.0
        && textureLod(dhDepthTex0, uv, 0.0).r == 1.0;
}

bool gfDhHasTranslucent(vec2 uv)
{
    float native0 = textureLod(depthtex0, uv, 0.0).r;
    float native1 = textureLod(depthtex1, uv, 0.0).r;
    if (native0 != native1) return true;
    if (!gfDhFrontAt(uv)) return false;
    return native1 < 1.0
        || textureLod(dhDepthTex0, uv, 0.0).r != textureLod(dhDepthTex1, uv, 0.0).r;
}

// Preserve the native shadow map. Distant receivers must not sample its
// clamped border beyond the existing shadow range.
vec3 gfDhReceiveShadow(vec4 clip, vec3 playerPos, float bias)
{
    float distanceXZ = length(playerPos.xz);
    if (distanceXZ >= shadowDistance || abs(clip.w) < 0.000001
        || length(clip.xy) < 0.000001) return vec3(1.0);
    vec3 ndc = distortShadowClipPos(clip.xyz) / clip.w;
    if (any(greaterThanEqual(abs(ndc), vec3(0.98)))) return vec3(1.0);
    vec3 shadow = getSoftShadow(clip, bias);
    return mix(shadow, vec3(1.0), smoothstep(shadowDistance * 0.8, shadowDistance, distanceXZ));
}

// Additional lens occlusion from visible DH mountains. Existing native
// shadow/lens calculations remain in place.
float gfDhSkyVisibility(vec2 uv)
{
    if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) return 1.0;
    return gfDhOpaqueAt(uv) ? 0.0 : 1.0;
}
#endif
#endif
