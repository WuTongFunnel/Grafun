const float EPS = 1e-6;




// 单位球单个球冠立体角，halfAngle 为半张角（弧度）
float capSolidAngle(float halfAngle) {
    return 2.0 * PI * (1.0 - cos(halfAngle));
}
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
    if (earth_distance <= MC_r) return 0.0;
    float earth_halftheta = asin(clamp(MC_r / earth_distance, 0.0, 1.0));
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

vec2 intersectEarth(vec3 p, vec3 q)
{
    vec3 oc = q - earth_core_position;

    float b = dot(p, oc);
    float c = dot(oc, oc) - MC_ar * MC_ar;

    float delta = b * b - c;

    if (delta < 0.0)
        return vec2(-1.0);

    float s = sqrt(delta);

    return vec2(-b - s, -b + s);
}

vec4 opticalDepthColor(float cosvalue,float r)
{

float u=clamp(0.5*cosvalue+0.5,0.0,1.0),v=clamp((r-MC_r)/MC_atom_height,0.0,1);
vec4 ocolor=texture(transmittance,vec2(u,v));

return ocolor;
}
vec4 getOpticalDepth(vec3 P, vec3 dir)
{
    vec3 OP = P - earth_core_position;
    float r = length(OP);
    vec3 samplePoint = P;
    if(r <MC_r)return vec4(0);
    if(r > MC_ar)
    {
        // 射线 P + t*dir 和大气球相交，t>0 是前进方向
        float nt =intersectEarth(dir, P).x;
        if(nt<0)return vec4(0);
        samplePoint = P + nt * dir;
        OP = samplePoint - earth_core_position;
        r = length(OP); // 同步更新r！
    }

    vec3 up = OP / max(r, 1e-6);
    float mu = dot(up, dir);

    return opticalDepthColor(mu, r);
}

// Rayleigh 散射相函数
float rayleighPhase(float cosTheta)
{
    return (3.0 / (16.0 * PI)) *
           (1.0 + cosTheta * cosTheta);
}

vec2 intersectGround(vec3 ro, vec3 rd)
{
    vec3 oc = ro - earth_core_position;
    rd = normalize(rd);

    float b = dot(oc, rd);
    float c = dot(oc, oc) - MC_r * MC_r;

    float delta = b * b - c;

    // 不与地球相交
    if (delta < 0.0)
        return vec2(-1.0);

    float s = sqrt(delta);

    float t0 = -b - s; // 近交点
    float t1 = -b + s; // 远交点

    return vec2(t0, t1);
}

// Mie 散射相函数（Henyey-Greenstein）
float miePhase(float cosTheta)
{
    
    const float mie_g = 0.76;

    float g2 = mie_g * mie_g;

    return (1.0 / (4.0 * PI)) *
           (1.0 - g2) /
           pow(1.0 + g2 - 2.0 * mie_g * cosTheta, 1.5);
}
vec3 getOzoneOpticalDepth(vec3 P, vec3 dir)
{

  //return vec3(0.0);
    vec3 OP = P - earth_core_position;
    float r = length(OP);

    if (r > MC_ar)
    {
        dir = normalize(dir);

        float nt = intersectEarth(dir, P).x;
        if (nt < 0.0)
            return vec3(0.0);

        P += nt * dir;
        OP = P - earth_core_position;
        r = length(OP);
    }

    vec3 up = OP / max(r, 1e-6);
    float mu = dot(up, normalize(dir));

    vec2 uv = vec2(
        clamp(0.5 * mu + 0.5, 0.0, 1.0),
        clamp((r - MC_r) / MC_atom_height, 0.0, 1.0)
    );

    return texture(ozone, uv).rgb;
}
vec3 onlyafterT(vec3 P, vec3 dir)
{
    vec4 tau = getOpticalDepth(P, dir);

    vec3 ozoneTau = getOzoneOpticalDepth(P, dir);

    return exp(-(
        tau.rgb +
        vec3(tau.a) +
        ozoneTau
    ));
}

vec4 grafunSegmentTau(vec3 segmentMid, vec3 rayDir, float ds)
{
    const float k = 0.2886751345948129; // 1/(2*sqrt(3))
    vec3 p0 = segmentMid - rayDir * (ds * k);
    vec3 p1 = segmentMid + rayDir * (ds * k);
    float h0 = length(p0 - earth_core_position) - MC_r;
    float h1 = length(p1 - earth_core_position) - MC_r;
    float rCol = 0.0;
    float mCol = 0.0;
    if (h0 >= 0.0 && h0 <= MC_atom_height) {
        rCol += exp(-h0 / (8000.0 / earth_factor));
        mCol += exp(-h0 / (1200.0 / earth_factor));
    }
    if (h1 >= 0.0 && h1 <= MC_atom_height) {
        rCol += exp(-h1 / (8000.0 / earth_factor));
        mCol += exp(-h1 / (1200.0 / earth_factor));
    }
    float km = ds * earth_factor * 0.0005; // meters -> km, average 2 samples
    return vec4(vec3(0.005802, 0.013558, 0.0331) * (rCol * km),
                0.003996 * (mCol * km));
}
  vec4 sun_pixel = gbufferProjection * vec4(sun_view, 1.0);
       vec4 nsun_pixel = sun_pixel/sun_pixel.w;
        vec2 SunUv = nsun_pixel.xy * 0.5 + 0.5;
        vec3 point_mulitscatter(vec3 p,vec3 sun_world)
        {
            
       vec3 OP = p - earth_core_position;
    float r = length(OP);
    vec3 dir=OP/r;
    float psun_thetac=dot(dir,sun_world);
float u=clamp(0.5*psun_thetac+0.5,0.0,1.0);
   float  h=clamp((r-MC_r)/MC_atom_height,0.0,1);
   float v=sqrt(h);
   return texture(multiscattering,vec2(u,v)).rgb;

        }
vec3 Atomfog(
    vec3 color,
    vec3 startPos,
    vec3 endPos,
    int rm_t
)
{
    float rm_all_l = length(endPos - startPos);

    if (rm_all_l/MC_atom_height <= 0.0 || rm_t <= 0)
        return color;

    vec3 rm_v = (endPos - startPos) / rm_all_l;

    float rm_dx = rm_all_l / float(rm_t);

    float sun_view_cos = clamp(
        dot(rm_v, normalize(sun_world)),
        -1.0,
        1.0
    );

    float sun_r_phase = rayleighPhase(sun_view_cos);
    float sun_m_phase = miePhase(sun_view_cos);

    // 仅当 sunangle > 0.5 时计算月光，避免白天执行月光相关开销。
    // sunangle 需要由当前光影包的全局 uniform / include 提供。
    bool moonEnabled = sunAngle > 0.5;
    float moon_r_phase = 0.0;
    float moon_m_phase = 0.0;

    if (moonEnabled)
    {
        // 月光沿 -sun_world 方向入射。
        float moon_view_cos = clamp(
            dot(rm_v, -normalize(sun_world)),
            -1.0,
            1.0
        );
        moon_r_phase = rayleighPhase(moon_view_cos);
        moon_m_phase = miePhase(moon_view_cos);
    }

    vec3 allcolor =color;

    vec3 rm_p = endPos - 0.5 * rm_v * rm_dx; 


   vec4 backsigema = getOpticalDepth(
        endPos,
        rm_v
    );
   vec3 Ozonebacksigema = getOzoneOpticalDepth(
        endPos,
        rm_v
    );
    vec4 frontsigema = vec4(0);
    vec3 Ozonefrontsigema = vec3(0);
    for (int i = 1; i < rm_t + 1; i++)
    {
  
        vec3 checkTp = rm_p - 0.5 * rm_v * rm_dx;

        frontsigema = getOpticalDepth(checkTp, rm_v);
        Ozonefrontsigema = getOzoneOpticalDepth(checkTp, rm_v);
        vec4 rm_p_sigema =frontsigema - backsigema;
         vec3 Ozonerm_p_sigema=Ozonefrontsigema-Ozonebacksigema;
 if(any(lessThan(rm_p_sigema, vec4(0.4)))){
    rm_p_sigema = grafunSegmentTau(rm_p, rm_v, rm_dx);
 }
        vec3 ocolor = allcolor;
        vec3 scatter_color = vec3(0);

        vec3 p_suncolor = light_color * onlyafterT(rm_p, sun_world);
        vec3 p_mooncolor = vec3(0.0);
        if (moonEnabled)
        {
            p_mooncolor = moon_color * onlyafterT(rm_p, -sun_world);
        }

        vec3 rm_p_rT = exp(-rm_p_sigema.rgb);
        float rm_p_mT = exp(-rm_p_sigema.a);
     vec3 rm_p_OzoneT = exp(-Ozonerm_p_sigema);
        vec3 rm_p_T = rm_p_rT * rm_p_mT*rm_p_OzoneT;

        ocolor *= rm_p_T;

        float m_s = 0.92;

        float visble = sunCanReachPoint(rm_p, sun_world);
        float moon_visble = 0.0;
        if (moonEnabled)
        {
            moon_visble = sunCanReachPoint(rm_p, -sun_world);
        }

        // 太阳大气散射
        scatter_color +=
            (1 - rm_p_rT) * sun_r_phase * p_suncolor * visble;

        scatter_color += m_s * (1 - rm_p_mT) * sun_m_phase * p_suncolor * visble;
#ifndef Highscatter
        vec3 highscatter_color = light_color*point_mulitscatter(rm_p,sun_world)*((1 - rm_p_rT) + m_s * (1 - rm_p_mT) );
        scatter_color += highscatter_color;
#endif

        // 仅在 sunangle > 0.5 时累积月光散射。
        if (moonEnabled)
        {
            scatter_color +=
                (1 - rm_p_rT) * moon_r_phase * p_mooncolor * moon_visble;

            scatter_color +=
                m_s * (1 - rm_p_mT) * moon_m_phase * p_mooncolor * moon_visble;
#ifndef Highscatter
            vec3 moon_highscatter_color =  moon_color *point_mulitscatter(rm_p,-sun_world)*((1 - rm_p_rT) + m_s * (1 - rm_p_mT) );
            scatter_color += moon_highscatter_color;
            #endif
        }


        rm_p -= rm_v * rm_dx;
        backsigema = frontsigema;
        Ozonebacksigema=Ozonefrontsigema;
        allcolor = ocolor + scatter_color;
    }

    return allcolor;
}
float pingpong(float t, float a)
{
    float m = mod(t, 2.0 * a);
    return a - abs(m - a);
}

// Earthpicture is a standard full-globe equirectangular atlas.
// gfEarthFramePose() is the continuously transported local-to-globe frame.
// The quaternion remains continuous through both poles; latitude is never
// folded and the local east axis is never independently mirrored.
//
// A lat-long atlas has an unavoidable coordinate singularity at each pole.
// There longitude is undefined, so use the transported local east axis as
// the deterministic limiting meridian instead of evaluating atan(0, 0).
// V maps the COMPLETE geographic latitude range [-PI/2,+PI/2] to [0,1].
vec2 earthSphericalUV(vec3 localNormal)
{
    vec4 q = gfEarthFramePose();

    vec3 localN = normalize(localNormal);
    vec3 globeNormal = normalize(gfEarthRotateVector(q, localN));

    float horizontalRadius = length(globeNormal.xy);

    // Stable pole meridian from the same transported frame.
    // At a pole the local tangent axes lie in the globe's equatorial plane.
    vec3 poleReference = gfEarthRotateVector(q, vec3(1.0, 0.0, 0.0));
    vec2 poleReferenceXY = poleReference.xy;

    // A defensive fallback for orientations where transported local +X
    // happens to align with the geographic pole axis.
    if (dot(poleReferenceXY, poleReferenceXY) < 1e-8)
    {
        poleReference = gfEarthRotateVector(q, vec3(0.0, 0.0, 1.0));
        poleReferenceXY = poleReference.xy;
    }

    float poleLongitude = (dot(poleReferenceXY, poleReferenceXY) > 1e-12)
        ? atan(poleReferenceXY.x, poleReferenceXY.y)
        : 0.0;

    float longitude = (horizontalRadius > 1e-6)
        ? atan(globeNormal.x, globeNormal.y)
        : poleLongitude;

    float latitude = atan(globeNormal.z, horizontalRadius);

    // Preserve the existing horizontal atlas rotation and east/west sense.
    float u = fract(0.8 + longitude / (2.0 * PI));

    // Critical fix: 0.5 is the equator. 0.395 shifted the entire atlas
    // south by 18.9 degrees and made the 71.1-degree row become the north pole.
    float v = 0.5 + latitude / PI;

    // Never sample exactly V=0 or V=1: with GL_REPEAT this would blend the
    // north and south edges. Half-texel inset selects the actual pole row.
    float texHeight = float(max(textureSize(Earthpicture, 0).y, 1));
    float halfTexelV = 0.5 / texHeight;
    v = clamp(v, halfTexelV, 1.0 - halfTexelV);

    return vec2(u, v);
}


// Earth surface skylight retains the original hemisphere integration helpers.
// Forward declarations: definitions are intentionally retained below.
vec3 HammersleyCosHemisphereDir(uint i, uint sampleTotal, vec3 N);
vec3 subAtomfog(vec3 color, vec3 rayOrigin, vec3 pixel_world, float depth);

vec3 airglow(vec3 position, vec3 direction)
{
    const float C557 =7.69e-15*sun_see_color.r;
    const float C630 = 1.69e-15*sun_see_color.r;

    // CIE 1931 2-degree color matching functions
    const vec3 CMF557 = vec3(0.5566, 0.9973, 0.0047);
    const vec3 CMF630 = vec3(0.6424, 0.2650, 0.0000);

    // 4-point Gauss-Legendre quadrature
    const float GX[4] = float[4](
        -0.8611363116,
        -0.3399810436,
         0.3399810436,
         0.8611363116
    );

    const float GW[4] = float[4](
        0.3478548451,
        0.6521451549,
        0.6521451549,
        0.3478548451
    );

    const float PROFILE_NORM = 2.392576;

    float worldToKm = earth_factor * 0.001;

    if (dot(direction, direction) < 1e-12)
        return vec3(0.0);

    vec3 dir = normalize(direction);
    vec3 oc = position - earth_core_position;

    float r0 = length(oc);

    if (r0 < MC_r - 1e-3)
        return vec3(0.0);

    float b = dot(oc, dir);
    float oc2 = dot(oc, oc);

    vec3 XYZ = vec3(0.0);

    for (int layer = 0; layer < 2; ++layer)
    {
        bool green = layer == 0;

        float minH = green ? 80.0 : 145.0;
        float maxH = green ? 112.0 : 355.0;

        float peak = green ? 96.0 : 250.0;
        float sigma = green ? 8.0 : 52.5;

        float C = green ? C557 : C630;

        vec3 CMF = green ? CMF557 : CMF630;

        float innerR = MC_r + minH / worldToKm;
        float outerR = MC_r + maxH / worldToKm;

        // Outer shell intersection
        float outerD =
            b * b - (oc2 - outerR * outerR);

        if (outerD <= 0.0)
            continue;

        float outerS = sqrt(outerD);

        float t0 = max(-b - outerS, 0.0);
        float t1 = -b + outerS;

        // Earth occlusion
        float groundD =
            b * b - (oc2 - MC_r * MC_r);

        if (groundD >= 0.0)
        {
            float groundNear =
                -b - sqrt(groundD);

            if (groundNear > 0.0)
                t1 = min(t1, groundNear);
        }

        if (t1 <= t0)
            continue;

        // Inner shell intersection
        float innerD =
            b * b - (oc2 - innerR * innerR);

        float innerNear = -1.0;
        float innerFar = -1.0;

        if (innerD >= 0.0)
        {
            float innerS = sqrt(innerD);

            innerNear = -b - innerS;
            innerFar  = -b + innerS;
        }

        // There can be two visible shell segments.
        for (int branch = 0; branch < 2; ++branch)
        {
            float segStart = t0;
            float segEnd = t1;

            if (innerD >= 0.0)
            {
                if (branch == 0)
                    segEnd = min(t1, innerNear);
                else
                    segStart = max(t0, innerFar);
            }
            else if (branch == 1)
            {
                continue;
            }

            if (segEnd <= segStart)
                continue;

            float mid = 0.5 * (segStart + segEnd);
            float halfLen = 0.5 * (segEnd - segStart);

            float pathIntegral = 0.0;

            for (int j = 0; j < 4; ++j)
            {
                float t = mid + halfLen * GX[j];

                vec3 P = position + dir * t;

                float h =
                    (length(P - earth_core_position) - MC_r)
                    * worldToKm;

                float x = (h - peak) / sigma;

                float density =
                    exp(-0.5 * x * x) /
                    (sigma * PROFILE_NORM);

                float dsKm =
                    halfLen * GX[j] * 0.0 +
                    halfLen * GW[j] * worldToKm;

                pathIntegral += density * dsKm;
            }

            XYZ += C * pathIntegral * CMF;
        }
    }

    // CIE XYZ -> Linear sRGB
    vec3 RGB = vec3(
         3.2406 * XYZ.x - 1.5372 * XYZ.y - 0.4986 * XYZ.z,
        -0.9689 * XYZ.x + 1.8758 * XYZ.y + 0.0415 * XYZ.z,
         0.0557 * XYZ.x - 0.2040 * XYZ.y + 1.0570 * XYZ.z
    );

    return onlyafterT(position,direction)*max(RGB, vec3(0.0));
}


vec3 earth(
    vec3 groundPoint,
    vec3 viewDir
)
{
        vec3 normal = normalize(
        groundPoint - earth_core_position
    );

    // 直接对球面法线做球面经纬度映射，不再将球面展开为平面。
    // Earthpicture 应为标准的等距圆柱（经纬度）全球纹理。
    vec2 earthuv = earthSphericalUV(normal);
    vec3 earthcolor = 0.88*pow(texture(Earthpicture, earthuv).rgb, vec3(2.2));
    if (E(earthcolor) > 0.006)
    {
        // Preserve the Earth diffuse skylight used in the earlier Grafun version.
        vec3 sunlight =
            clamp(dot(sun_world, normal), 0.0, 1.0)
            * light_color;
                vec3 moonlight =
            clamp(dot(-sun_world, normal), 0.0, 1.0)
            * moon_color;
        vec3 skylightColor = vec3(0.0);
  //sunlight*=onlyafterT(groundPoint, sun_world);
  //moonlight*=onlyafterT(groundPoint, -sun_world);
       /* const uint SKY_SAMPLES = 16u;
        for (uint i = 0u; i < SKY_SAMPLES; ++i)
        {
            vec3 sampleDir = HammersleyCosHemisphereDir(i, SKY_SAMPLES, normal);
            skylightColor += subAtomfog(skybackground(sampleDir, vec2(0.0, 9.0), 1.0, 1.0).rgb, groundPoint, sampleDir, 1.0);
        }
        skylightColor *= PI / float(SKY_SAMPLES);*/
              vec3 starlightColor = vec3(0.0);
        {
        
                const uint SKY_SAMPLES = 16u;
           for (uint i = 0u; i < SKY_SAMPLES; ++i)
        {
            vec3 sampleDir = HammersleyCosHemisphereDir(i, SKY_SAMPLES, normal);
            starlightColor += skybackground(sampleDir, vec2(0.0, 9.0), 1.0, 1.0).rgb;
#ifdef AIRGLOW
            starlightColor += airglow(groundPoint, sampleDir);
#endif
        }
        skylightColor *= PI / float(SKY_SAMPLES);
    }
        return earthcolor * (moonlight+ sunlight+skylightColor+ starlightColor) / PI;
    }
    // 反射大气固定步数，与主视线 steps 完全解耦。
    const int reflectionSteps = 16;
    // ========================================================
    // 1. 地球交点处的局部法线与反射方向
    // ========================================================


    vec3 reflectedDir = normalize(
        reflect(viewDir, normal)
    );



    {
        // 反射方向必须朝地表外侧。
        if (dot(reflectedDir, normal) <= 0.0)
        {
            return skybackground(
                vec3(viewDir.x, abs(viewDir.y), viewDir.z),
                vec2(0.0),
                1,
                0
            ).rgb;
        }

        // ====================================================
        // 2. 求反射方向上的大气区间
        // ====================================================

        float surfaceEpsilon = max(
            1e-4,
            abs(MC_r) * 1e-7
        );

        vec3 reflectedOrigin =
            groundPoint + normal * surfaceEpsilon;

        vec2 reflectedOuterHit = intersectEarth(
            reflectedDir,
            reflectedOrigin
        );

        vec3 reflectedSkyBase = onlyafterT(groundPoint, sun_world)*skybackground(
            vec3(
                reflectedDir.x,
                abs(reflectedDir.y),
                reflectedDir.z
            ),
            vec2(0.0),
            1,
            0
        ).rgb;

        if (reflectedOuterHit.y <= 0.0)
            return reflectedSkyBase;

        float reflectedA = max(
            reflectedOuterHit.x,
            0.0
        );

        float reflectedB = reflectedOuterHit.y;

        if (reflectedB <= reflectedA)
            return reflectedSkyBase;

        vec3 reflectedStart =
            reflectedOrigin + reflectedDir * reflectedA;

        vec3 reflectedEnd =
            reflectedOrigin + reflectedDir * reflectedB;

        float farLength = length(
            reflectedEnd - reflectedStart
        );

        if (farLength <= 1e-4)
            return reflectedSkyBase;

        // ====================================================
        // 3. 反射大气使用固定步数
        //
        // 不读取主视线 steps；
        // 不参与两段路径的总步数分配。
        // ====================================================

        float F = 0.0204 + (1.0 - 0.0204) * pow(
            1.0 - max(0.0, dot(-viewDir, normal)),
            5.0
        );

        vec3 farColor = Atomfog(
            reflectedSkyBase,
            reflectedStart,
            reflectedEnd,
            reflectionSteps
        );

        // 返回反射方向计算得到的天空颜色。
        // atmosphere() 会独立使用自己的 steps 计算相机到地表的大气。
        return F * farColor;
    }

    // 未来 if 条件为 false 时代表陆地：
    // 不反射，保留天空底色；由 atmosphere() 继续计算第一段大气。
    return skybackground(
        vec3(viewDir.x, abs(viewDir.y), viewDir.z),
        vec2(0.0),
        1,
        0
    ).rgb;
}


// ============================================================
// INDEPENDENT EARTH RENDERER: origin + direction ONLY
// Return rgb = shaded planet, a = 1 if hit, 0 if no hit.
// Keeps earth() material, hemisphere diffuse skylight and sea reflection.
// ============================================================
vec4 renderEarth(vec3 rayOrigin, vec3 viewDir)
{
    float rayLen = length(viewDir);
    if (rayLen < 1e-6) return vec4(0.0);

    vec3 dir = viewDir / rayLen;
    vec2 hit = intersectGround(rayOrigin, dir);
    if (hit.y < 0.0) return vec4(0.0);

    float epsilon = max(1e-4, abs(MC_r) * 1e-7);
    float radius = length(rayOrigin - earth_core_position);
    float t = -1.0;

    // Prefer the first front-facing intersection. When underground, the
    // sphere exit is not an exterior Earth surface: keep the legacy view.
    if (radius < MC_r - epsilon)
        return vec4(0.0);

    if (hit.x > epsilon)
        t = hit.x;
    else if (abs(radius - MC_r) <= epsilon && radius > 1e-5 &&
             dot(dir, (rayOrigin - earth_core_position) / radius) < -1e-5 &&
             hit.y > epsilon)
        t = 0.0;

    if (t < 0.0) return vec4(0.0);
    vec3 surfacePoint = rayOrigin + dir * t;
    return vec4(earth(surfacePoint, dir), 1.0);
}

vec3 atmosphere(
    vec3 rayOrigin,
    vec3 pixel_world,
    vec3 color,
    float depth,
    int steps
)
{
    // This function NEVER shades the Earth and NEVER creates background stars.
    // Its 'color' input is the scene/sky/Earth color already selected by caller.
    if (steps <= 0) return color;

    vec3 rayVector = pixel_world - rayOrigin;
    float rayLength = length(rayVector);
    if (rayLength < 1e-4) return color;

    vec3 dir = rayVector / rayLength;
    bool isSky = depth >= 0.999999;

    // A below-sea-level camera cannot see atmospheric sky through the
    // lower hemisphere. Return the caller's background without integrating
    // the atmosphere along a ray that points into the solid planet.
    if (isSky && gfShouldBlockLowerHemisphereSky(dir))
        return color;

    vec2 atmosphereHit = intersectEarth(dir, rayOrigin);
    if (atmosphereHit.y <= 0.0) return color;

    float startT = max(atmosphereHit.x, 0.0);
    float endT = isSky
        ? atmosphereHit.y
        : min(atmosphereHit.y, rayLength);
    float epsilon = max(1e-4, abs(MC_r) * 1e-7);

    vec2 groundHit = intersectGround(rayOrigin, dir);
    vec3 cameraOffset = rayOrigin - earth_core_position;
    float cameraRadius = length(cameraOffset);
    bool insideEarth = cameraRadius < MC_r - epsilon;
    bool atSurface = abs(cameraRadius - MC_r) <= epsilon;

    if (insideEarth)
    {
        // Preserve the previous underground handling: only integrate outside
        // the solid globe, and do NOT synthesize skybackground here.
        if (groundHit.y <= 0.0) return color;
        startT = max(startT, groundHit.y);
    }
    else
    {
        float groundT = -1.0;
        if (groundHit.x > epsilon && groundHit.x >= startT &&
            groundHit.x < atmosphereHit.y)
            groundT = groundHit.x;
        else if (atSurface && cameraRadius > 1e-5 &&
                 dot(dir, cameraOffset / cameraRadius) < -1e-5 &&
                 groundHit.y > epsilon)
            groundT = 0.0;

        // Geometric occlusion only: stop the ray at the solid Earth.
        // Never replace the input color with sky or Earth shading.
        if (groundT >= 0.0 && groundT < endT)
            endT = groundT;
    }

    if (endT <= startT) return color;
    return Atomfog(color,
        rayOrigin + dir * startT,
        rayOrigin + dir * endT,
        steps);
}



// 输入：i样本序号，sampleTotal总样本数，N世界空间单位法线
// 返回：世界空间入射方向wi，pdf = dot(N,wi)/PI
vec3 HammersleyCosHemisphereDir(uint i, uint sampleTotal, vec3 N)
{
    // Hammersley 2D低差异序列（bit反转，和你原始代码完全一致）
    uint bits = i;
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    float rInv = float(bits) * 2.3283064365386963e-10;
    vec2 xi = vec2(float(i)/float(sampleTotal), rInv);

    // 余弦加权半球采样（局部切空间，局部z=法线方向）
    float u = xi.x;
    float v = xi.y;
    float phi = 2.0 * PI * u;
    float z = sqrt(v);
    float r = sqrt(max(0.0, 1.0 - v));
    vec3 localWi = vec3(r * cos(phi), r * sin(phi), z);

// 更稳定的TBN，避免cross接近0产生NaN
vec3 up = vec3(0.0,1.0,0.0);
if(abs(dot(N,up)) > 0.999) up = vec3(1,0,0);
vec3 T = normalize(cross(up, N));
vec3 B = cross(N, T);
mat3 TBN = mat3(T,B,N);


    return normalize(TBN * localWi);
}
vec3 subAtomfog(vec3 color,   vec3 rayOrigin,
    vec3 pixel_world,
    float depth)
{
    vec3 rm_v= normalize(pixel_world);
    vec2 eartht= intersectEarth( rm_v,rayOrigin);
    float eartht1=max(eartht.x,0);
      float eartht2=max(eartht.y,0);

      
         if(depth!=1.0)
      {
         float lp=length(pixel_world-rayOrigin);
           eartht2=min(lp, eartht2);
      }

      float rm_all_l=eartht2-eartht1;
      if(depth!=1.0)    
      {
    return color;
      }
            float rm_t=16;
float rm_dx=rm_all_l/rm_t;
      float sun_view_cos=clamp(
        dot(rm_v, normalize(sun_world)),
        -1.0,
        1.0
    );
    float sun_r_phase=rayleighPhase(sun_view_cos);
    float sun_m_phase=miePhase(sun_view_cos);

    // 与 Atomfog 使用相同的月光开关。
    bool moonEnabled = sunAngle > 0.5;
    float moon_r_phase = 0.0;
    float moon_m_phase = 0.0;
    if (moonEnabled)
    {
        float moon_view_cos=clamp(
            dot(rm_v, -normalize(sun_world)),
            -1.0,
            1.0
        );
        moon_r_phase=rayleighPhase(moon_view_cos);
        moon_m_phase=miePhase(moon_view_cos);
    }

    vec3 allcolor=color;
      vec3 rm_p=rayOrigin+eartht2*rm_v-0.5*rm_v*rm_dx;
      vec4 backsigema=getOpticalDepth( rm_p+0.5*rm_v*rm_dx,rm_v);
      vec4 frontsigema=vec4(0);
      for(int i=1;i<rm_t+1;i++)
{
    float rm_r=length(rm_p-earth_core_position);
   
          vec3 checkTp=rm_p-0.5*rm_v*rm_dx;
    frontsigema=getOpticalDepth(checkTp,rm_v);
    vec4 rm_p_sigema=abs(frontsigema-backsigema);
    vec3 ocolor=allcolor;
    vec3 scatter_color=vec3(0);


   vec3 p_suncolor=light_color*onlyafterT(rm_p,sun_world);
   vec3 p_mooncolor=vec3(0.0);
   if (moonEnabled)
   {
       p_mooncolor=moon_color*onlyafterT(rm_p,-sun_world);
   }
   //
      vec3 rm_p_rT=exp(-rm_p_sigema.rgb);
  float rm_p_mT=exp(-rm_p_sigema.a);
  vec3 rm_p_T= rm_p_rT*rm_p_mT;
  ocolor*=rm_p_T;
  float m_s=0.7;
  float visble=sunCanReachPoint(rm_p, sun_world);
  float moon_visble=0.0;
  if (moonEnabled)
  {
      moon_visble=sunCanReachPoint(rm_p, -sun_world);
  }

  // 太阳大气散射
  scatter_color+=(1-rm_p_rT)*sun_r_phase*p_suncolor*visble;
    scatter_color+=m_s*(1-rm_p_mT)*sun_m_phase*p_suncolor*visble;
        vec3 highscatter_color = light_color*point_mulitscatter(rm_p,sun_world)*((1 - rm_p_rT) + m_s * (1 - rm_p_mT) );
    scatter_color+= highscatter_color;

  // 仅在 sunangle > 0.5 时累积月光散射。
  if (moonEnabled)
  {
      scatter_color+=(1-rm_p_rT)*moon_r_phase*p_mooncolor*moon_visble;
      scatter_color+=m_s*(1-rm_p_mT)*moon_m_phase*p_mooncolor*moon_visble;
            vec3 moon_highscatter_color =  moon_color *point_mulitscatter(rm_p,-sun_world)*((1 - rm_p_rT) + m_s * (1 - rm_p_mT) );
      scatter_color+=moon_highscatter_color;
  }
  //

rm_p-=rm_v*rm_dx;
  backsigema=frontsigema;
allcolor=ocolor+scatter_color;
}
return allcolor;
}

