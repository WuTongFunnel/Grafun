float halton(int idx, int base)
{
    float f = 1.0;
    float r = 0.0;
    while(idx > 0)
    {
        f /= float(base);
        r += f * float(idx % base);
        idx /= base;
    }
    return r;
}
// Halton(2,3)
vec2 jlitter(int frame)
{
    return vec2( (2*halton(frame,2)-1)/(viewWidth), (2*halton(frame,3)-1)/(viewHeight) );
}
uniform int frameCounter;
vec2 djlitter=jlitter(frameCounter);


