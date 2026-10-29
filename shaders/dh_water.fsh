
#version 450 compatibility
#include "/lib/function.glsl"

in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
flat in float isWater;

uniform float far;

/* RENDERTARGETS: 3,4,5,8 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 alpha;

void main()
{
#ifdef DISTANT_HORIZONS
    vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

    vec3 dhViewPos = gfDhViewPosition(
        uv,
        gl_FragCoord.z
    );
	float depth = texture(depthtex1, uv).r;
	if(depth < 1.0) {
		discard;
	}
	if(depth < 1.0) {
		discard;
	}

    // 保留原有不透明深度遮挡
    float nativeDepth =
        textureLod(depthtex0, uv, 0.0).r;

    if (nativeDepth < 1.0 &&
        gfNativeViewZ(uv, nativeDepth) >= dhViewPos.z)
    {
        discard;
    }
#endif

    if (glcolor.a < 0.001)
        discard;

    color = vec4(glcolor.rgb, 1.0);

    lightmapData = vec4(lmcoord, 0.0, 1.0);

    encodedNormal = vec4(
        normal * 0.5 + 0.5,
        1.0
    );

    alpha = vec4(
        isWater > 0.5 ? 0.125 : glcolor.a,
        0.0,
        0.0,
        1.0
    );
}
