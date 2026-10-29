float cloudbottom=0.015*MC_atom_height+MC_r ;
float cloudtop=0.04*MC_atom_height+MC_r ;


vec3 cloudMod289(vec3 x)
{
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 cloudMod289(vec4 x)
{
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 cloudPermute(vec4 x)
{
    return cloudMod289(
        ((x * 34.0) + 1.0) * x
    );
}

vec4 cloudTaylorInvSqrt(vec4 r)
{
    return 1.79284291400159
         - 0.85373472095314 * r;
}


float cloudSimplex3D(vec3 v)
{
    const vec2 C = vec2(
        1.0 / 6.0,
        1.0 / 3.0
    );

    const vec4 D = vec4(
        0.0,
        0.5,
        1.0,
        2.0
    );

    // Skew 输入坐标
    vec3 i = floor(v + dot(v, C.yyy));

    vec3 x0 = v - i + dot(i, C.xxx);

    // 确定单纯形顶点偏移
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;

    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;

    // 排列哈希
    i = cloudMod289(i);

    vec4 p = cloudPermute(
        cloudPermute(
            cloudPermute(
                i.z + vec4(
                    0.0,
                    i1.z,
                    i2.z,
                    1.0
                )
            )
            + i.y + vec4(
                0.0,
                i1.y,
                i2.y,
                1.0
            )
        )
        + i.x + vec4(
            0.0,
            i1.x,
            i2.x,
            1.0
        )
    );

    // 梯度构造
    float n_ = 1.0 / 7.0;

    vec3 ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);

    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;

    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(
        x.xy,
        y.xy
    );

    vec4 b1 = vec4(
        x.zw,
        y.zw
    );

    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;

    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw
            + s0.xzyw * sh.xxyy;

    vec4 a1 = b1.xzyw
            + s1.xzyw * sh.zzww;

    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);

    // 梯度归一化
    vec4 norm = cloudTaylorInvSqrt(
        vec4(
            dot(p0, p0),
            dot(p1, p1),
            dot(p2, p2),
            dot(p3, p3)
        )
    );

    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // 四个顶点的距离衰减
    vec4 m = max(
        0.6 - vec4(
            dot(x0, x0),
            dot(x1, x1),
            dot(x2, x2),
            dot(x3, x3)
        ),
        0.0
    );

    m *= m;

    vec4 px = vec4(
        dot(p0, x0),
        dot(p1, x1),
        dot(p2, x2),
        dot(p3, x3)
    );

    m *= m;

    return 42.0 * dot(m, px);
}

const float CLOUD_PERIOD = 16.0;

float cloudPeriodicSimplex3D(vec3 p)
{
    vec3 q = mod(p, CLOUD_PERIOD);

    vec3 w = q / CLOUD_PERIOD;

    // 五次平滑曲线，保证周期边界处导数连续
    w = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);

    float result = 0.0;

    for (int z = 0; z < 2; ++z)
    {
        for (int y = 0; y < 2; ++y)
        {
            for (int x = 0; x < 2; ++x)
            {
                vec3 offset = vec3(x, y, z);

                vec3 weight = mix(
                    vec3(1.0) - w,
                    w,
                    offset
                );

                float blend =
                    weight.x * weight.y * weight.z;

                result += blend * cloudSimplex3D(
                    q - offset * CLOUD_PERIOD
                );
            }
        }
    }

    return result;
}
float cloudNoise3D(vec3 p)
{
    vec3 uvw = fract(p / 4.0);
    return textureLod(cloudNoiseTex, uvw, 0.0).r * 2.0 - 1.0;
}
float cloudFBM4(vec3 p)
{
    float value = 0.0;

    float amplitude = 1.0;
    float totalAmplitude = 0.0;

    for (int octave = 0; octave < 8; ++octave)
    {
      float noiseValue = cloudNoise3D(p);

        noiseValue = noiseValue * 0.5 + 0.5;

        value += noiseValue * amplitude;
        totalAmplitude += amplitude;

        p *= 1.99;
        amplitude *= 0.625;
    }

    return clamp(
        value / totalAmplitude,
        0.0,
        1.0
    );
}



float cloudDensity(vec3 p)
{
    vec3 flatPos = spherical_unmapping(p)*earth_factor;
        vec2 wind=0.05*frameTimeCounter*vec2(0,-1);
     vec3 trans=vec3(wind.x,0,wind.y);
   float lp= length(p-earth_core_position);
    float normalized_height =
    (lp - cloudbottom) /
    (cloudtop - cloudbottom);

float base_factor =
    smoothstep(0.0, 0.2, normalized_height);

float top_factor =
    1.0 - smoothstep(
        0.8, 1.0, normalized_height
    );

float height_factor =
   normalized_height;
   float d=cloudFBM4(0.0001*flatPos+trans);
   float width=0.015,threshold=0.525;
   float density=smoothstep(threshold-width,threshold+width,d);
return normalized_height*density;
}

float cloudsigema(vec3 p)
{
    const float CloudreferenceScattering = 0.00125;

    return cloudDensity(p) *
           CloudreferenceScattering;
}


vec2 sphereIntersect(
    vec3 rayOrigin,
    vec3 rayDir,
    float radius
)
{
    vec3 rd = normalize(rayDir);

    // 从球心指向射线起点的向量
    vec3 oc = rayOrigin - earth_core_position;

    // 二次方程：t² + 2*b*t + c = 0
    float b = dot(oc, rd);
    float c = dot(oc, oc) - radius * radius;

    float discriminant = b * b - c;

    if (discriminant < 0.0)
    {
        return vec2(-1.0, -1.0);
    }

    float sqrtD = sqrt(discriminant);

    float tNear = -b - sqrtD;
    float tFar  = -b + sqrtD;

    return vec2(tNear, tFar);
}


float cloudtransmisson(vec3 beginpostion,vec3 endpostion)
{
float t=1;
float rm_all_l = length(endpostion - beginpostion);
if(rm_all_l<0.1)
{
    return t;
}
vec3 rm_v = normalize(endpostion-beginpostion);
float rm_t=16;
float rm_dx=rm_all_l/rm_t;
float cloud_phase = dot(rm_v, sun_world); 
float cloud_mie_g = 0.75;
float g1 = cloud_mie_g, g2 = -cloud_mie_g, k = 0.5;
float cloud_mie_phase = k*(1.-g1*g1)/(4.*PI*pow(1.+g1*g1-2.*g1*cloud_phase,1.5)) + (1.-k)*(1.-g2*g2)/(4.*PI*pow(1.+g2*g2-2.*g2*cloud_phase,1.5));
vec3 rm_p=endpostion;
float dxmeter=(rm_dx)*earth_factor;
for(int i=1;i<rm_t+1;i++)
{
rm_p-=rm_v*rm_dx;
  float sigmaS = cloudsigema(rm_p);
float opticalDepth = sigmaS * dxmeter;
float T = exp(-opticalDepth);
float optical=1-T;
t*=T;
}
return t;
}
// 计算从当前采样点沿太阳方向传播时，穿过云层后的透射率。
// rayOrigin、earth_core_position 必须处于相同坐标空间。
// sunDir 必须指向太阳，并且与求交函数使用相同的坐标空间。
float cloudSunTransmittance(
    vec3 rayOrigin,
    vec3 sunDir
)
{
    vec3 dir = normalize(sunDir);

    // 1. 求外球交点
    vec2 outerHit = sphereIntersect(
        rayOrigin,
        dir,
        cloudtop
    );

    // 外球完全在射线后方
    if (outerHit.y <= 0.0)
    {
        return 1.0;
    }

    // 只考虑射线前方的区间
    float outerA = max(outerHit.x, 0.0);
    float outerB = outerHit.y;

    if (outerB <= outerA)
    {
        return 1.0;
    }

    // 2. 求内球交点
    vec2 innerHit = sphereIntersect(
        rayOrigin,
        dir,
        cloudbottom
    );

    // 初始透射率
    float T = 1.0;

    // 3. 内球没有与有效外球区间相交
    // 只需要计算一段云层
    if (
        innerHit.x < 0.0 && innerHit.y < 0.0
        || innerHit.y <= outerA
        || innerHit.x >= outerB
    )
    {
        vec3 beginPos = rayOrigin + dir * outerA;
        vec3 endPos   = rayOrigin + dir * outerB;

        return cloudtransmisson(
            beginPos,
            endPos
        );
    }

    // 4. 内球区间与外球区间求交
    float innerA = max(innerHit.x, outerA);
    float innerB = min(innerHit.y, outerB);

    // 第一段：进入内球之前的云层
    if (innerA > outerA)
    {
        vec3 beginPos = rayOrigin + dir * outerA;
        vec3 endPos   = rayOrigin + dir * innerA;

        T *= cloudtransmisson(
            beginPos,
            endPos
        );
    }

    // 第二段：离开内球之后的云层
    if (outerB > innerB)
    {
        vec3 beginPos = rayOrigin + dir * innerB;
        vec3 endPos   = rayOrigin + dir * outerB;

        T *= cloudtransmisson(
            beginPos,
            endPos
        );
    }

    return T;
}
vec3 cloudfog(vec3 color,vec3 beginpostion,vec3 endpostion)
{
vec3 allcolor = color;
float rm_all_l = length(endpostion - beginpostion);
if(rm_all_l<0.1)
{
    return allcolor;
}
vec3 rm_v = normalize(endpostion-beginpostion);
float rm_t=64; // Temporary real-time density test; raise to 64-128 after comparison.
float rm_dx=rm_all_l/rm_t;
float cloud_phase = dot(rm_v, sun_world); // cosTheta
float cloud_mie_g = 0.75;
float g1 = cloud_mie_g, g2 = -cloud_mie_g, k = 0.5;
float cloud_mie_phase = k*(1.-g1*g1)/(4.*PI*pow(1.+g1*g1-2.*g1*cloud_phase,1.5)) + (1.-k)*(1.-g2*g2)/(4.*PI*pow(1.+g2*g2-2.*g2*cloud_phase,1.5));

vec3 rm_p=endpostion;
float dxmeter=(rm_dx)*earth_factor;
for(int i=1;i<rm_t+1;i++)
{
rm_p-=rm_v*rm_dx;
float sun_to_rm_p = sunRayAtmLength(rm_p, sun_world);
  vec3 p_suncolor=light_color*scatterf(sun_to_rm_p/MC_atom_height)*(1-fog_kk(sun_to_rm_p/MC_atom_height,sun_theta_s));


  float sigmaS = cloudsigema(rm_p);
  if(sigmaS<0.00002)continue;
    float sunCloudT = cloudSunTransmittance(
    rm_p,
    sun_world
);

p_suncolor *= sunCloudT;
vec3 p_allcolor=  p_suncolor;
  p_suncolor*=sunCanReachPoint(rm_p, sun_world);
float opticalDepth = sigmaS * dxmeter;
float T = exp(-opticalDepth);
float optical=1-T;
allcolor*=T;
allcolor+=(p_suncolor*cloud_mie_phase)*optical;
 vec3 g_color=p_allcolor*opticalDepth*(1.0/(4*PI));
allcolor+= g_color;
}
return allcolor;
}

vec3 cloud(
    vec3 rayOrigin,
    vec3 pixel_world,
    vec3 color,
    float depth
)
{
    vec3 rayVector = pixel_world - rayOrigin;
    float rayLength = length(rayVector);

    if (rayLength < 0.1)
    {
        return color;
    }

    vec3 dir = rayVector / rayLength;

    // 1. 云层外球交点
    vec2 outerHit = sphereIntersect(
        rayOrigin,
        dir,
        cloudtop
    );

    if (outerHit.y <= 0.0)
    {
        return color;
    }

    // 2. 根据场景深度设置射线最大距离
    float maxT = depth >= 0.999999
        ? outerHit.y
        : rayLength;

    // 3. 地球球体交点
    vec2 earthHit = sphereIntersect(
        rayOrigin,
        dir,
        MC_r
    );

    // 如果射线从地球外部进入地球，
    // 就在第一个正向交点处截断
    if (earthHit.x > 0.0)
    {
        maxT = min(maxT, earthHit.x);
    }
    else if (earthHit.x <= 0.0 && earthHit.y > 0.0)
    {
        // 摄像机位于地球内部时，不沿此方向渲染云
        return color;
    }

    // 4. 云层外球有效区间
    float outerA = max(outerHit.x, 0.0);
    float outerB = min(outerHit.y, maxT);

    if (outerB <= outerA)
    {
        return color;
    }

    // 5. 云层内球交点
    vec2 innerHit = sphereIntersect(
        rayOrigin,
        dir,
        cloudbottom
    );

    // 没有与内球重叠：整个区间都是云层
    if (
        (innerHit.x < 0.0 && innerHit.y < 0.0) ||
        innerHit.y <= outerA ||
        innerHit.x >= outerB
    )
    {
        return cloudfog(
            color,
            rayOrigin + dir * outerA,
            rayOrigin + dir * outerB
        );
    }

    // 6. 云层分段积分
    float innerA = max(innerHit.x, outerA);
    float innerB = min(innerHit.y, outerB);

    // 进入内球前的云层
    if (innerA > outerA)
    {
        color = cloudfog(
            color,
            rayOrigin + dir * outerA,
            rayOrigin + dir * innerA
        );
    }

    // 离开内球后的云层
    if (outerB > innerB)
    {
        color = cloudfog(
            color,
            rayOrigin + dir * innerB,
            rayOrigin + dir * outerB
        );
    }

    return color;
}