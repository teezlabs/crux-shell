import QtQuick
import qs.Commons

// Base text element: every Text should be an NText so size, weight and tracking come from Tokens.
// Tiers carry the lighter weight of each pair; override font.weight for the heavier one.
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
  // Opt-in: older layouts were measured without tracking and clip with it (docs/design-notes.md).
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

  // Eases colour like surfaces do; false where a label must track a value instantly.
  property bool animateColor: true

  opacity: enabled ? 1.0 : 0.6
  color: Colors.surfaceText

  Behavior on color {
    enabled: root.animateColor
    ColorAnimation {
      duration: Tokens.durationColor
      easing.type: Tokens.easingColor
    }
  }

  Behavior on opacity {
    NumberAnimation {
      duration: Tokens.durationColor
      easing.type: Tokens.easingColor
    }
  }
  font.family: root.mono ? Tokens.monoFontFamily : Tokens.fontFamily
  font.pixelSize: root.tierSize
  font.weight: root.tierWeight
  font.letterSpacing: root.tracking ? root.tierSize * root.tierTracking : 0
  elide: Text.ElideRight
  wrapMode: Text.NoWrap
  verticalAlignment: Text.AlignVCenter
}
