// When the camera is below Minecraft sea level, the lower hemisphere is
// inside the solid planet and must not be treated as visible sky.
// direction is a camera-relative world-space ray direction.
bool gfShouldBlockLowerHemisphereSky(vec3 direction)
{
    if (cameraPosition.y >= MC_sealevel)
        return false;

    float directionLength2 = dot(direction, direction);
    if (directionLength2 <= 1e-12)
        return false;

    vec3 localUp = -earth_core_position;
    float upLength2 = dot(localUp, localUp);
    if (upLength2 <= 1e-12)
        localUp = vec3(0.0, 1.0, 0.0);
    else
        localUp *= inversesqrt(upLength2);

    return dot(direction * inversesqrt(directionLength2), localUp) < 0.0;
}

// Vacuum background: no Rayleigh, Mie, LUT or atmospheric refraction.
vec4 skybackground(vec3 pixel_world, vec2 texcoord, float depth, float r)
{
    if (gfShouldBlockLowerHemisphereSky(pixel_world))
        return vec4(0.0, 0.0, 0.0, 1.0);

    vec3 dir = gfStarRotation * normalize(pixel_world);
    vec2 uv = vec2(atan(dir.z, dir.x) / (2.0 * PI) + 0.5,
                   acos(clamp(-dir.y, -1.0, 1.0)) / PI);
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
          vec4 stark = vec4(sun_see_color.r) * (7.72e-11);
    if(r>0)
{
  vec4 starcolor=stark*texture(starmaplight, uv);
  color.rgb=starcolor.rgb;
  return  color;
}
    if (depth ==1.0)
    {
        color.rgb =stark.rgb * texture(starmap, uv).rgb;
        vec4 sunDisc = texture(colortex11, texcoord);
if(dot(sun_world,pixel_world)>cos(radians(0.25)))  color.rgb = sun_see_color;
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
