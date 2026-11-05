#ifndef GRAFUN_EARTH_ROTATION_GLSL
#define GRAFUN_EARTH_ROTATION_GLSL

// ---------------------------------------------------------------------------
// Stateful Earth rotation, independent of latitude/longitude singularities.
// Existing colortex10: RGBA32F, colortex10Clear=false, TAA temporal history.
// Only composite9 writes the Earth quaternion and its frame marker.
// composite4 reads the same old state + current frame displacement.
//
// World +X: geographic west (the user's negative-east convention).
// World -Z: north.  At the starting location, local basis=(-X,+Y,-Z).
// ---------------------------------------------------------------------------
uniform vec3 previousCameraPosition;
const ivec2 GF_EARTH_ROTATION_PIXEL = ivec2(0, 0);
const ivec2 GF_EARTH_MARKER_PIXEL   = ivec2(1, 0);
const vec3 GF_EARTH_MARKER = vec3(17321.0, 24567.0, 31415.0);

vec4 gfEarthQuatMul(vec4 a, vec4 b)
{
    return vec4(
        a.w * b.xyz + b.w * a.xyz + cross(a.xyz, b.xyz),
        a.w * b.w - dot(a.xyz, b.xyz)
    );
}

vec4 gfEarthQuatNormalize(vec4 q)
{
    return q * inversesqrt(max(dot(q, q), 1e-30));
}

vec3 gfEarthRotateVector(vec4 q, vec3 v)
{
    vec3 t = 2.0 * cross(q.xyz, v);
    return v + q.w * t + cross(q.xyz, t);
}

// The increment is expressed in the camera's transported LOCAL frame.
// Angle = (path length / effective Minecraft globe radius).
vec4 gfEarthLocalStep(vec2 movementXZ)
{
    float lengthXZ = length(movementXZ);
    if (lengthXZ < 1e-7)
        return vec4(0.0, 0.0, 0.0, 1.0);

    // Use half-angle periodicity for numerical stability during teleports.
    float halfAngle = 0.5 * mod(lengthXZ / max(MC_r, 1e-6), 2.0 * PI);
    vec3 axis = vec3(movementXZ.y, 0.0, -movementXZ.x) / lengthXZ;
    return vec4(axis * sin(halfAngle), cos(halfAngle));
}

// Reset case: when history is missing, use a deterministic single great-circle
// path from (0,0) to current camera XZ. It cannot reconstruct traveled loops.
vec4 gfEarthInitialPose()
{
    vec4 base = vec4(0.0, 1.0, 0.0, 0.0); // 180-degree rotation around Y
    return gfEarthQuatNormalize(
        gfEarthQuatMul(base, gfEarthLocalStep(cameraPosition.xz))
    );
}

vec4 gfEarthFramePose()
{
    if (frameCounter <= 0)
        return gfEarthInitialPose();

    vec4 tag  = texelFetch(colortex10, GF_EARTH_MARKER_PIXEL, 0);
    vec4 oldQ = texelFetch(colortex10, GF_EARTH_ROTATION_PIXEL, 0);

    int expectedFrame = (frameCounter - 1) % 65536;
    bool tagValid = all(equal(tag.xyz, GF_EARTH_MARKER)) &&
                    abs(tag.w - float(expectedFrame)) < 0.25;
    float qLength2 = dot(oldQ, oldQ);
    bool qValid = !any(isnan(oldQ)) && !any(isinf(oldQ)) &&
                  qLength2 > 0.9 && qLength2 < 1.1;
    if (!tagValid || !qValid)
        return gfEarthInitialPose();

    vec2 delta = cameraPosition.xz - previousCameraPosition.xz;
    return gfEarthQuatNormalize(
        gfEarthQuatMul(oldQ, gfEarthLocalStep(delta))
    );
}

#endif
