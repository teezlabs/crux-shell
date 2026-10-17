#ifndef ROUNDING_GLSL
#define ROUNDING_GLSL
// Crux override of Hyprland's rounding.glsl: per-corner 45° chamfers instead of a superellipse.

// Stock shadow.glsl still references these.
#define M_PI               3.1415926535897932384626433832795
#define SMOOTHING_CONSTANT (M_PI / 5.34665792551)

float distanceWithRounding(vec2 coords, float roundingPower) {
    return pow(pow(coords.x, roundingPower) + pow(coords.y, roundingPower), 1.0 / roundingPower);
}

// Corner bits: TL=1 TR=2 BR=4 BL=8. Services/WindowCorners.qml rewrites the mask from settings.
#define CRUX_DEFAULT_MASK 10

// rounding_power in [3, 4) carries a mask as 3 + mask / 16; anything else uses the default.
int cruxCornerMask(float roundingPower) {
    if (roundingPower >= 3.0 && roundingPower < 4.0)
        return int(floor((roundingPower - 3.0) * 16.0 + 0.5));
    return CRUX_DEFAULT_MASK;
}

// Maps a framebuffer offset into the surface's own orientation, so rotated monitors cut the right corner.
vec2 cruxLogicalSide(vec2 p, vec2 uv) {
    vec2 dx = dFdx(uv);
    vec2 dy = dFdy(uv);
    return vec2(dx.x * p.x + dy.x * p.y, dx.y * p.x + dy.y * p.y);
}

// side < 0 means left / top.
int cruxCornerBit(vec2 side) {
    if (side.x < 0.0)
        return side.y < 0.0 ? 1 : 8;
    return side.y < 0.0 ? 2 : 4;
}

float cruxChamferDist(vec2 p, vec2 halfSize, float cut) {
    vec2  q = abs(p) - halfSize;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
    if (cut > 0.0)
        d = max(d, (q.x + q.y + cut) * 0.70710678);
    return d;
}

vec4 rounding(vec4 color, float radius, float roundingPower, vec2 topLeft, vec2 fullSize) {
    vec2 p = gl_FragCoord.xy - (topLeft + fullSize * 0.5);
#ifdef CRUX_NO_TEXCOORD
    vec2 side = p;
#else
    vec2 side = cruxLogicalSide(p, v_texcoord);
#endif
    bool  cut = (cruxCornerMask(roundingPower) & cruxCornerBit(side)) != 0;
    float a   = clamp(0.5 - cruxChamferDist(p, fullSize * 0.5, cut ? radius : 0.0), 0.0, 1.0);

    if (a <= 0.0)
        discard;

    return color * a;
}
#endif
