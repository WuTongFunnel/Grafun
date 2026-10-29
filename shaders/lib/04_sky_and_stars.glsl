// Vacuum background: no Rayleigh, Mie, LUT or atmospheric refraction.
vec4 skybackground(vec3 pixel_world, vec2 texcoord, float depth, float r)
{
    vec3 dir = gfStarRotation * normalize(pixel_world);
    vec2 uv = vec2(atan(dir.z, dir.x) / (2.0 * PI) + 0.5,
                   acos(clamp(-dir.y, -1.0, 1.0)) / PI);
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
    if(r>0)
{
  vec4 starcolor=STAR_BRIGHTNESS*sunk*(1.0/400000) * texture(starmaplight, uv);
  color.rgb=starcolor.rgb;
  return  color;
}
    if (depth >= 0.999999)
    {
        color.rgb = STAR_BRIGHTNESS * sunk * (1.0 / 400000.0) * texture(starmap, uv).rgb;
        vec4 sunDisc = texture(colortex11, texcoord);
        if (sunDisc.a > 0.5)
            color.rgb = sunDisc.rgb;
        color.rgb = moon(normalize(pixel_world), color.rgb);
    }
    return color;
}

vec4 sky(vec2 texcoord, float depth, float r)
{
    vec3 direction = screenxyz_to_worldxyz(vec4(texcoord, depth, 1.0));
    return skybackground(direction, texcoord, depth, 0.0);
}

vec4 reflect_sky(vec3 direction, float r)
{
    return skybackground(direction, vec2(0.0), 1.0, 0.0);
}
