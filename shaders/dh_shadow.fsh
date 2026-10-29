#version 450 compatibility

in vec4 glcolor;
flat in float isWater;
layout(location = 0) out vec4 color;

void main()
{
    // DH LODs supply their albedo/opacity through vertex color, not gtexture UVs.
    color = glcolor;

    if (color.a < 0.1)
        discard;

    // Keep Grafun's existing low-opacity water shadow behavior.
    if (isWater > 0.5)
        color.a = 0.125;
}
