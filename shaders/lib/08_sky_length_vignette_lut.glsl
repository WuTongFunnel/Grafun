
float Vignette_G(float x, float y)
{
    float sx = sqrt(1.0 + x * x);
    float sy = sqrt(1.0 + y * y);

    return 0.5 * (
        x / sx * atan(y / sx) +
        y / sy * atan(x / sy)
    );
}
float Vignette_integralRect(vec3 fp, float a)
{
  float xc=fp.x;
  float yc=fp.y;
    float x1 = xc - a;
    float x2 = xc + a;
    float y1 = yc - a;
    float y2 = yc + a;

    return Vignette_G(x2, y2)
         - Vignette_G(x1, y2)
         - Vignette_G(x2, y1)
         + Vignette_G(x1, y1);
}
float  Vignette_classic(vec3 fp)
{
   float cosp=1.0/length(fp);
      float fk=pow(cosp,4.0);
      return fk;
}
vec3 lut_texcoord(vec3 pixel_world,vec3 sun_dir)
{
    const float EPS = 1e-6f;
    float sun_cos = clamp(sun_dir.y, -1.0f, 1.0f);
    float pixel_cos = clamp(pixel_world.y, -1.0f, 1.0f);
    float cosGamma = 0.0f;
    if(sun_cos < 1.0f - EPS && pixel_cos < 1.0f - EPS)
    {
        vec2 a = normalize(vec2(sun_dir.x, sun_dir.z));
        vec2 b = normalize(vec2(pixel_world.x, pixel_world.z));
        cosGamma = clamp(dot(a,b), -1.0f, 1.0f); // 关键clamp，防止>1 / <-1
    }
    float x = acos(pixel_cos)/PI;
    float y = acos(sun_cos)/PI;
    float z = acos(cosGamma)/PI;
    return vec3(x,y,z);
}
