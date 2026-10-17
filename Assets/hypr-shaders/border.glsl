#ifndef ALLOW_INCLUDES
#define ALLOW_INCLUDES
#extension GL_ARB_shading_language_include : enable
#endif
#include "cm_helpers.glsl"
#include "gradient.glsl"
// Crux: chamfer helpers are needed even without rounding.
#include "rounding.glsl"

#if USE_MIRROR
vec4[2]
#else
vec4
#endif
    getBorder(vec2 v_texcoord, float alpha, vec2 fullSizeUntransformed, float radiusOuter, float thick, float radius, float roundingPower, vec2 topLeft, vec2 fullSize,
              int gradientLength, vec4 gradient[10], float angle, int gradient2Length, vec4 gradient2[10], float angle2, float gradientLerp
#if USE_CM
              ,
              int sourceTF, int targetTF, mat3 convertMatrix, vec2 srcTFRange, vec2 dstTFRange
#if USE_ICC
              ,
              highp sampler3D iccLut3D, float iccLutSize
#else
#if USE_TONEMAP || USE_SDR_MOD
              ,
              mat3 targetPrimariesXYZ
#endif
#if USE_TONEMAP
              ,
              float maxLuminance, float dstMaxLuminance, float dstRefLuminance, float srcRefLuminance, int tonemapMode
#endif
#if USE_SDR_MOD
              ,
              float sdrSaturation, float sdrBrightnessMultiplier
#endif
#endif
#endif
    ) {
    vec2  p = vec2(gl_FragCoord) - (topLeft + fullSize * 0.5);
    vec2  h = fullSize * 0.5;
    vec4  pixColor;

    // radius is the window's cut plus thick. The outer cut grows by thick * (2 - sqrt 2) so the diagonal keeps the edges' width.
    float cutIn  = 0.0;
    float cutOut = 0.0;
#if USE_ROUNDING
    bool cut = radius > 0.0 && (cruxCornerMask(roundingPower) & cruxCornerBit(cruxLogicalSide(p, v_texcoord))) != 0;
    if (cut) {
        cutIn  = max(radius - thick, 0.0);
        cutOut = cutIn + thick * 0.58578644;
    }
#endif

    float outer           = clamp(0.5 - cruxChamferDist(p, h, cutOut), 0.0, 1.0);
    float inner           = clamp(0.5 - cruxChamferDist(p, h - thick, cutIn), 0.0, 1.0);
    float additionalAlpha = outer * (1.0 - inner);

    if (additionalAlpha <= 0.0)
        discard;

    pixColor = getColorForCoord(v_texcoord, gradientLength, gradient, angle, gradient2Length, gradient2, angle2, gradientLerp);
    pixColor.rgb *= pixColor[3];

#if USE_CM
    return doColorManagement(pixColor, alpha * additionalAlpha, sourceTF, targetTF, convertMatrix, srcTFRange, dstTFRange
#if USE_ICC
                             ,
                             iccLut3D, iccLutSize
#else
#if USE_TONEMAP || USE_SDR_MOD
                             ,
                             targetPrimariesXYZ
#endif
#if USE_TONEMAP
                             ,
                             maxLuminance, dstMaxLuminance, dstRefLuminance, srcRefLuminance, tonemapMode
#endif
#if USE_SDR_MOD
                             ,
                             sdrSaturation, sdrBrightnessMultiplier
#endif
#endif
    );
#endif

#if USE_MIRROR
    vec4[2] pixColors;
    pixColors[0] = pixColor * alpha * additionalAlpha;
    pixColors[1] = pixColors[0];
    return pixColors;
#else
    pixColor *= alpha * additionalAlpha;
    return pixColor;
#endif
}

