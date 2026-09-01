import QtQuick
import qs.Commons

// Control Center 2x2 toggle tile (§6.3): active tile gets primaryContainer
// fill + a small filled triangle in the top-right corner as the on-marker
// (per spec text — confirmed against the mockup, which shows exactly that
// on the WIFI/BLUETOOTH tiles). Inactive/unavailable: plain surface, grey
// text, non-interactive when `enabled` is false (no fake toggle for a
// service crux doesn't have, e.g. Night Light).
Item {
  id: root

  property string label: ""
  property string value: ""
  property bool active: false
  property bool available: true
  // Whether this tile has more than an on/off state behind it (a real
  // device list — Wifi networks, Bluetooth devices) worth right-clicking
  // into. Purely a visual hint (a small corner tick); tiles without one
  // (MIC, NIGHT LIGHT) just don't show it.
  property bool expandable: false
  signal tapped
  signal expandRequested

  Rectangle {
    anchors.fill: parent
    color: root.active ? Color.primaryContainer : Color.surface
    opacity: root.available ? 1 : 0.5
  }

  Canvas {
    id: marker
    visible: root.active
    width: 9
    height: 9
    anchors.top: parent.top
    anchors.right: parent.right
    readonly property color triColor: Color.primary
    onTriColorChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d");
      ctx.reset();
      ctx.fillStyle = triColor;
      ctx.beginPath();
      ctx.moveTo(width, 0);
      ctx.lineTo(width, height);
      ctx.lineTo(0, 0);
      ctx.closePath();
      ctx.fill();
    }
  }

  Column {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: 10
    spacing: 2

    Text {
      text: root.label
      color: root.active ? Color.primary : Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.weight: Font.DemiBold
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
    Text {
      text: root.value
      color: root.active ? Color.primaryContainerText : Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySize
      font.weight: Font.DemiBold
      elide: Text.ElideRight
      width: root.width - 20
    }
  }

  // Bottom-left corner tick: the same "there's more here" affordance the
  // top-right on-marker uses, just a fixed hint rather than a state marker
  // — visible whenever this tile actually has a fuller popup behind it.
  Canvas {
    visible: root.expandable
    width: 6
    height: 6
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    readonly property color tickColor: Color.labelText
    onTickColorChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d");
      ctx.reset();
      ctx.fillStyle = tickColor;
      ctx.beginPath();
      ctx.moveTo(width, height);
      ctx.lineTo(width, 0);
      ctx.lineTo(0, height);
      ctx.closePath();
      ctx.fill();
    }
  }

  HoverHandler {
    enabled: root.available
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    enabled: root.available
    acceptedButtons: Qt.LeftButton
    onTapped: root.tapped()
  }
  TapHandler {
    enabled: root.available && root.expandable
    acceptedButtons: Qt.RightButton
    onTapped: root.expandRequested()
  }
}
