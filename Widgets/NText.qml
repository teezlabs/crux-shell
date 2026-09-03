import QtQuick
import qs.Commons

// Base text element for the whole shell. Every Text in crux should be an
// NText so the type scale, tracking and family come from Tokens rather
// than being retyped at each call site.
//
// `size` picks a tier from the spec's type scale and carries that tier's
// weight and letter-spacing with it; override font.weight afterwards for
// the heavier variant of a pair (the tokens hold the lighter one).
Text {
  id: root

  enum Size {
    Display,
    Title,
    BodyLg,
    Body,
    BodySm,
    Caption,
    Label,
    LabelXs
  }

  property int size: NText.Size.Body
  property bool mono: false
  // The spec gives each tier a letter-spacing, but most existing layouts
  // were measured without it and clip if it's applied retroactively — so
  // it stays opt-in per call site rather than riding on the tier.
  property bool tracking: false

  readonly property int tierSize: {
    switch (root.size) {
    case NText.Size.Display:
      return Tokens.displaySize;
    case NText.Size.Title:
      return Tokens.titleSize;
    case NText.Size.BodyLg:
      return Tokens.bodyLgSize;
    case NText.Size.BodySm:
      return Tokens.bodySmSize;
    case NText.Size.Caption:
      return Tokens.captionSize;
    case NText.Size.Label:
      return Tokens.labelSize;
    case NText.Size.LabelXs:
      return Tokens.labelXsSize;
    }
    return Tokens.bodySize;
  }

  readonly property int tierWeight: {
    switch (root.size) {
    case NText.Size.Display:
      return Tokens.displayWeight;
    case NText.Size.Title:
      return Tokens.titleWeight;
    case NText.Size.BodyLg:
      return Tokens.bodyLgWeight;
    case NText.Size.BodySm:
      return Tokens.bodySmWeight;
    case NText.Size.Caption:
      return Tokens.captionWeight;
    case NText.Size.Label:
      return Tokens.labelWeight;
    case NText.Size.LabelXs:
      return Tokens.labelXsWeight;
    }
    return Tokens.bodyWeight;
  }

  // Tokens store tracking as an em fraction; Qt wants absolute px.
  readonly property real tierTracking: {
    switch (root.size) {
    case NText.Size.Display:
      return Tokens.displayTracking;
    case NText.Size.Title:
      return Tokens.titleTracking;
    case NText.Size.BodyLg:
      return Tokens.bodyLgTracking;
    case NText.Size.BodySm:
      return Tokens.bodySmTracking;
    case NText.Size.Caption:
      return Tokens.captionTracking;
    case NText.Size.Label:
      return Tokens.labelTracking;
    case NText.Size.LabelXs:
      return Tokens.labelXsTracking;
    }
    return Tokens.bodyTracking;
  }

  opacity: enabled ? 1.0 : 0.6
  color: Color.surfaceText
  font.family: root.mono ? Tokens.monoFontFamily : Tokens.fontFamily
  font.pixelSize: root.tierSize
  font.weight: root.tierWeight
  font.letterSpacing: root.tracking ? root.tierSize * root.tierTracking : 0
  elide: Text.ElideRight
  wrapMode: Text.NoWrap
  verticalAlignment: Text.AlignVCenter
}
