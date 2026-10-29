vec3 moon(vec3 pixel_world, vec3 color)
{
    // 球心和观察点关系由顶点阶段计算，视线求交仍逐像素进行。
    vec3 moon_core = gfMoonCore;
    vec3 d = normalize(pixel_world);
    vec3 C = moon_core;

    // ========== 球体求交 ==========
    float b = -2.0 * dot(d, C);
    float c = gfMoonIntersectionC;
    float delta = b * b - 4.0 * c;
    if (delta < 0.0) return color;

    float sqrtDelta = sqrt(delta);
    float t = (-b - sqrtDelta) / 2.0;
    if (gfMoonInside > 0.5) t = (-b + sqrtDelta) / 2.0;
    if (t < 0.0) return color;

    vec3 moon_p = t * d;
    vec3 op = normalize(moon_p - moon_core);

    // ========== 光照方向（保留 moon_sun_world）==========
    vec3 moon_sun_world = gfMoonSunWorld;

    // ========== 局部正交基（用旋转后的太阳方向作为 z 轴）==========
    vec3 z_axis = gfMoonBasisZ;
    vec3 y_axis = gfMoonBasisY;
    vec3 x_axis = gfMoonBasisX;

    // ========== 世界 → 局部 ==========
    vec3 p = vec3(dot(op, x_axis),- dot(op, y_axis), dot(op, z_axis));

    // ========== 局部 → uv（lon = atan(p.x, p.z)）==========
    float lon = atan(p.x, p.z);
    float lat = asin(clamp(p.y, -1.0, 1.0));
    vec2 uv = vec2(lon / (2.0 * PI) + 0.5, lat / PI + 0.5);

    // ========== 高度图偏导 ==========
    const float R0_KM = 1737.4;
    float eps = 1.0 / 5760.0;

    float h0_km = texture(MoonHeight, uv).r;
    float hu_km = texture(MoonHeight, uv + vec2(eps, 0.0)).r;
    float hv_km = texture(MoonHeight, uv + vec2(0.0, eps)).r;

    float h0 = h0_km / R0_KM;
    float hu = hu_km / R0_KM;
    float hv = hv_km / R0_KM;

    float h_u = (hu - h0) / eps;
    float h_v = (hv - h0) / eps;

    // ========== uv → 局部球面（与 lon 定义严格一致）==========
    float lonL = (2.0 * uv.x - 1.0) * PI;
    float latL = (2.0 * uv.y - 1.0) * PI * 0.5;

    float cosLat = cos(latL), sinLat = sin(latL);
    float cosLon = cos(lonL), sinLon = sin(lonL);

    vec3 r = vec3(
        cosLat * sinLon,   // x
        sinLat,            // y
        cosLat * cosLon    // z
    );

    vec3 drdu = vec3(
         cosLat * cosLon,
         0.0,
        -cosLat * sinLon
    ) * (2.0 * PI);

    vec3 drdv = vec3(
        -sinLat * sinLon,
         cosLat,
        -sinLat * cosLon
    ) * PI;

    // ========== 切向量 ==========
    vec3 dPdu = h_u * r + (1.0 + h0) * drdu;
    vec3 dPdv = h_v * r + (1.0 + h0) * drdv;

    // ========== 局部法线（cross 朝外，无需负号）==========
    vec3 N_local = normalize(cross(dPdu, dPdv));

    // ========== 局部 → 世界 ==========
    vec3 moon_normal = normalize(N_local.x * x_axis + N_local.y * y_axis + N_local.z * z_axis);

    // ========== 光照 ==========
    vec3 moon_albedo = texture(Moonpicture, uv).rgb * MOON_ALBEDO_SCALE + MOON_ALBEDO_OFFSET;
    vec3 moon_view_world = -d;

    float NdotL = clamp(dot(moon_normal, moon_sun_world), 0.0, 1.0);
    float NdotV = clamp(dot(moon_normal, moon_view_world), 0.0, 1.0);

    float cosG = clamp(dot(moon_sun_world, moon_view_world), -1.0, 1.0);
    float g = acos(cosG);

    float B0 = 0.8;
    float hh = 0.015;
    float B = B0 / (1.0 + tan(g * 0.5) / hh);

    float ghg = -0.35;
    float cosg = cos(g);
    float P_hg = (1.0 - ghg * ghg) / pow(1.0 + ghg * ghg - 2.0 * ghg * cosg, 1.5);

    float denom = max(NdotL + NdotV, 1e-6);
    vec3 hapke = moon_albedo / (4.0 * PI) * (NdotL / denom) * (P_hg + B);

#if MOON_BRIGHTNESS != 100
    hapke *= float(MOON_BRIGHTNESS) / 100.0;
#endif
    return hapke;
}
