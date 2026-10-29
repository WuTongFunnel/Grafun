#version 450 compatibility

in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 watercolor;

void main()
{
    // Same G-buffer contract as gbuffers_terrain. Grafun's existing deferred
    // lighting, atmosphere and postprocessing shade the LOD later.
    color = vec4(glcolor.rgb, 1.0);
    lightmapData = vec4(lmcoord, 0.0, 1.0);
    encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
    watercolor = vec4(1.0, 1.0, 1.0, 0.0);
    // Native opaque draws AFTER DH: never reject here using stale native depth.
}
