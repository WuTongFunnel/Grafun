float intersectEarthT1(vec3 p,vec3 q)
{
    vec3 E = earth_core_position;
    vec3 oc = q - E;
    float b = 2.0 * dot(p, oc);
    float c = dot(oc, oc) - MC_ar * MC_ar;

    float delta = b*b - 4.0 * c;
    if(delta < 0.0)
    {
        return -1.0;
    }
    float sqrtDelta = sqrt(delta);
    float t1 = (-b - sqrtDelta) / 2.0;
    return max(0.0, t1);
}
// p必须是单位方向向量
float intersectEarthT2(vec3 p,vec3 q)
{
    vec3 E = earth_core_position;
    vec3 oc = q - E;
    float b = 2.0 * dot(p, oc);
    float c = dot(oc, oc) - MC_ar * MC_ar;

    float delta = b*b - 4.0 * c;
    if(delta < 0.0)
    {
        return -1.0;
    }
    float sqrtDelta = sqrt(delta);
    float t1 = (-b + sqrtDelta) / 2.0;
    return max(0.0, t1);
}

float sunRayAtmLength(vec3 P, vec3 sunDir)
{
    vec3 E = earth_core_position;
    vec3 rel = P - E;
    float A = dot(sunDir, rel);
    float lenRelSq = dot(rel, rel);
    float R = MC_ar;

    float delta = A*A - (lenRelSq - R*R);
    if(delta < 0.0) return 0.0;

    float sqrtDelta = sqrt(delta);
    float t = -A - sqrtDelta; // ✅ 负号保留，正确
    return max(max(-A - sqrtDelta,-A + sqrtDelta), 0.0);
}
const float EPS = 1e-6;

// 单位球单个球冠立体角，halfAngle 为半张角（弧度）
float capSolidAngle(float halfAngle) {
    return 2.0 * PI * (1.0 - cos(halfAngle));
}

// 两个球冠相交立体角，alpha、beta、gamma 均为弧度
// alpha: 球冠A半张角
// beta:  球冠B半张角
// gamma: 两球冠对称轴夹角
float intersectCapsSolidAngle(float alpha, float beta, float gamma) {
    alpha = clamp(alpha, 0.0, PI);
    beta  = clamp(beta,  0.0, PI);
    gamma = clamp(gamma, 0.0, PI);

    // 一个球冠覆盖整个球面，则交集等于另一个球冠
    if (alpha >= PI - EPS) return capSolidAngle(beta);
    if (beta  >= PI - EPS) return capSolidAngle(alpha);

    // 两轴几乎反向：背对背，无交集
    if (gamma >= PI - EPS) return 0.0;

    // 完全分离，无交集
    if (gamma >= alpha + beta - EPS) return 0.0;

    // 一个球冠完全包含另一个
    if (gamma <= abs(alpha - beta) + EPS)
        return capSolidAngle(min(alpha, beta));

    float sa = sin(alpha);
    float sb = sin(beta);
    float sg = sin(gamma);

    // 角度趋近0，保护除零
    if (sa < EPS || sb < EPS || sg < EPS) return 0.0;

    float lambdaA = acos(clamp(
        (cos(beta) - cos(alpha) * cos(gamma)) / (sa * sg),
        -1.0, 1.0));

    float lambdaB = acos(clamp(
        (cos(alpha) - cos(beta) * cos(gamma)) / (sb * sg),
        -1.0, 1.0));

    float lambdaP = acos(clamp(
        (cos(gamma) - cos(alpha) * cos(beta)) / (sa * sb),
        -1.0, 1.0));

    float omega = 2.0 * PI
                - 2.0 * (lambdaP
                       + lambdaA * cos(alpha)
                       + lambdaB * cos(beta));

    return clamp(omega, 0.0, capSolidAngle(min(alpha, beta)));
}

float sunCanReachPoint(vec3 P, vec3 sunDir)
{

    vec3 E = earth_core_position;
    vec3 v=normalize(E-P);
    float earth_distance = length(P - E);
    float earth_halftheta=asin(MC_r/earth_distance);
    if(earth_distance<MC_r)return 0;
    #if SUN_SIZE == 100
    float sun_halftheta=radians(0.25);
#else
    float sun_halftheta=radians(0.25 * float(SUN_SIZE) / 100.0);
#endif
    float sun_s=capSolidAngle(sun_halftheta);
    
    float dotVSun = dot(v, sunDir);
    dotVSun = clamp(dotVSun, -1.0, 1.0);
    float gamma = acos(dotVSun);
    
    float cross_s=intersectCapsSolidAngle(sun_halftheta,earth_halftheta,gamma);
    float sun_visible = sun_s - cross_s;
  
    return clamp(sun_visible / sun_s, 0.0, 1.0);
}

