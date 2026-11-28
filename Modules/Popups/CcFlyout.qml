import QtQuick
import qs.Commons
import qs.Widgets
import qs.Modules.Popups.Contents

// The Wi-Fi or Bluetooth list popping out beside the Control Center card, level with the tile that asked for it.
Item {
  id: root

  required property var host
  // The Control Center's SlideCard; the flyout only shows while it does.
  property Item card: null
  // "wifi" | "bluetooth" | ""
  property string which: ""
  // Window y of the tile the flyout lines up with.
  property real anchorY: 0
  signal closeRequested

  readonly property bool shown: root.which !== "" && !!root.card && root.card.shown
  // Keeps the last list on screen while the flyout fades out.
  property string _last: ""
  onWhichChanged: if (root.which !== "")
    root._last = root.which

  readonly property real pad: Tokens.spaceXl
  readonly property real margin: Tokens.spaceLg
  readonly property real _contentHeight: (root._last === "bluetooth" ? bt.implicitHeight : wifi.implicitHeight) + root.pad * 2
  // Beside the card on the side away from the bar, unless that runs off screen.
  readonly property bool onRight: !root.card || root.card.x + root.card.width + Tokens.spaceMd + root.width <= root.host.width - root.margin

  width: root._last === "bluetooth" ? 320 : 360
  height: Math.min(root._contentHeight, 560, root.host.height - root.margin * 2)
  x: !root.card ? 0 : root.onRight ? root.card.x + root.card.width + Tokens.spaceMd : root.card.x - Tokens.spaceMd - root.width
  y: Math.max(root.margin, Math.min(root.anchorY, root.host.height - root.height - root.margin))

  visible: opacity > 0
  opacity: root.shown ? 1 : 0
  Behavior on opacity {
    NumberAnimation {
      duration: Tokens.durationSidebarSlide
      easing.type: Tokens.easingSidebarSlide
    }
  }
  Behavior on height {
    NumberAnimation {
      duration: Tokens.durationPanel
      easing.type: Tokens.easingPanel
    }
  }

  // Slides out of the card's edge.
  transform: Translate {
    x: root.shown ? 0 : (root.onRight ? -Tokens.spaceXl : Tokens.spaceXl)
    Behavior on x {
      NumberAnimation {
        duration: Tokens.durationSidebarSlide
        easing.type: Tokens.easingSidebarSlide
      }
    }
  }

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferPanel
    cutTopRight: true
    cutBottomLeft: true
    fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
    strokeColor: Colors.outline
    strokeWidth: Tokens.borderPanel
    shadow: true
    rimLight: true
  }

  // Keeps clicks on the flyout from reaching the host's click-outside handler.
  MouseArea {
    anchors.fill: parent
    onClicked: {}
  }

  Item {
    anchors.fill: parent
    anchors.margins: root.pad
    clip: true

    WifiPanelContent {
      id: wifi
      anchors.fill: parent
      visible: root._last === "wifi"
      panelActive: root.shown && root.which === "wifi"
      onRequestClose: root.closeRequested()
    }
    BluetoothPanelContent {
      id: bt
      anchors.fill: parent
      visible: root._last === "bluetooth"
      panelActive: root.shown && root.which === "bluetooth"
    }
  }
}
