.pragma library

// OKLCH <-> sRGB hex (Björn Ottosson's OKLab), and crux's theme generator built on it.
// L is 0..1, C is chroma (about 0..0.37 inside sRGB), H is degrees.

function _toLinear(c) {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

function _toGamma(c) {
  return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
}

function _hex2(v) {
  var n = Math.max(0, Math.min(255, Math.round(v * 255)));
  return (n < 16 ? "0" : "") + n.toString(16);
}

// Linear sRGB for an OKLCH colour, unclamped.
function _rgb(L, C, H) {
  var h = H * Math.PI / 180;
  var a = C * Math.cos(h);
  var b = C * Math.sin(h);
  var l = Math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3);
  var m = Math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3);
  var s = Math.pow(L - 0.0894841775 * a - 1.2914855480 * b, 3);
  return [
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
  ];
}

function _inGamut(rgb) {
  var e = 0.0005;
  return rgb[0] >= -e && rgb[0] <= 1 + e && rgb[1] >= -e && rgb[1] <= 1 + e && rgb[2] >= -e && rgb[2] <= 1 + e;
}

// Hex for an OKLCH colour; out-of-gamut colours keep their lightness and hue and lose chroma until they fit.
function toHex(L, C, H) {
  L = Math.max(0, Math.min(1, L));
  var c = Math.max(0, C);
  var rgb = _rgb(L, c, H);
  if (!_inGamut(rgb)) {
    var lo = 0, hi = c;
    for (var i = 0; i < 24; i++) {
      var mid = (lo + hi) / 2;
      if (_inGamut(_rgb(L, mid, H)))
        lo = mid;
      else
        hi = mid;
    }
    rgb = _rgb(L, lo, H);
  }
  return "#" + _hex2(_toGamma(Math.max(0, Math.min(1, rgb[0])))) + _hex2(_toGamma(Math.max(0, Math.min(1, rgb[1])))) + _hex2(_toGamma(Math.max(0, Math.min(1, rgb[2]))));
}

// { L, C, H } for "#rrggbb"; H is 0 for greys.
function fromHex(hex) {
  var m = /^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i.exec(String(hex || ""));
  if (!m)
    return { "L": 0, "C": 0, "H": 0 };
  var r = _toLinear(parseInt(m[1], 16) / 255);
  var g = _toLinear(parseInt(m[2], 16) / 255);
  var b = _toLinear(parseInt(m[3], 16) / 255);
  var l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  var mm = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  var s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  var L = 0.2104542553 * l + 0.7936177850 * mm - 0.0040720468 * s;
  var A = 1.9779984951 * l - 2.4285922050 * mm + 0.4505937099 * s;
  var B = 0.0259040371 * l + 0.7827717662 * mm - 0.8086757660 * s;
  var C = Math.sqrt(A * A + B * B);
  var H = C < 1e-4 ? 0 : (Math.atan2(B, A) * 180 / Math.PI + 360) % 360;
  return { "L": L, "C": C, "H": H };
}

// Every crux theme role from one accent. mood scales how much colour the surfaces and accent carry:
// "muted" 0.5, "balanced" 1, "vivid" 1.6.
function generate(accentHex, mood) {
  var k = mood === "muted" ? 0.5 : mood === "vivid" ? 1.6 : 1;
  var a = fromHex(accentHex);
  var H = a.H;
  var accentC = Math.max(0.1 * k, Math.min(0.2, a.C));
  var tint = 0.012 * k;
  return {
    "surface": toHex(0.16, tint, H),
    "surfaceContainerLow": toHex(0.19, tint, H),
    "surfaceContainer": toHex(0.22, tint * 1.1, H),
    "surfaceContainerHigh": toHex(0.27, tint * 1.2, H),
    "outline": toHex(0.42, tint * 1.6, H),
    "outlineVariant": toHex(0.33, tint * 1.4, H),
    "primary": toHex(0.8, accentC, H),
    "primaryContainer": toHex(0.36, accentC * 0.45, H),
    "primaryContainerText": toHex(0.9, accentC * 0.35, H),
    "tertiary": toHex(0.8, accentC * 0.6, (H + 60) % 360),
    "errorTone": toHex(0.76, 0.14, 25),
    "surfaceText": toHex(0.93, tint * 0.8, H),
    "surfaceTextMuted": toHex(0.76, tint * 1.2, H),
    "primaryText": toHex(0.2, accentC * 0.25, H),
    "errorText": toHex(0.2, 0.04, 25)
  };
}
