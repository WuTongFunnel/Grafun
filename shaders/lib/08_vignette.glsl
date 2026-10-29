
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
