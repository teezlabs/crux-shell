import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.Commons

// Volume popup: default-output volume slider + mute toggle, and a list of
// available output devices to switch the default sink. Own primitives,
// same structural pattern as BluetoothMenuWindow.qml/WifiMenuWindow.qml.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  // Popup used to be hardcoded to the screen's top-right corner regardless
  // of where the bar actually is — wrong the moment the bar isn't on top
  // (e.g. this session's left-positioned vertical bar). Anchor to whichever
  // edge the bar occupies instead, offset past its thickness + float gap so
  // the popup sits flush beside it rather than overlapping.
  readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"
  readonly property bool _barLeft: root._barPos === "left"
  readonly property bool _barRight: root._barPos === "right"
  readonly property bool _barBottom: root._barPos === "bottom"
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin * 2 + 8

  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

  readonly property var allSinks: {
    if (!Pipewire.ready || !Pipewire.nodes)
      return [];
    return Pipewire.nodes.values.filter(function (n) {
      return n && n.isSink && !n.isStream;
    });
  }

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  function setVolume(v) {
    if (!sink || !sink.audio)
      return;
    sink.audio.volume = Math.max(0, Math.min(1, v));
  }

  function toggle() {
    visible = !visible;
  }

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-sound-menu"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "sound"
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
    }
    function close() {
      root.visible = false;
    }
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  // Soft drop shadow behind the card, same treatment as the bar itself
  // (shell.qml) — depth against whatever's behind the popup.
  MultiEffect {
    anchors.fill: card
    source: card
    shadowEnabled: true
    shadowColor: Qt.rgba(0, 0, 0, 0.55)
    shadowBlur: 0.7
    shadowVerticalOffset: 3
    shadowHorizontalOffset: 0
  }

  Rectangle {
    id: card
    anchors.top: !root._barBottom ? parent.top : undefined
    anchors.bottom: root._barBottom ? parent.bottom : undefined
    anchors.left: root._barLeft ? parent.left : undefined
    anchors.right: !root._barLeft ? parent.right : undefined
    anchors.topMargin: !root._barBottom ? (root._barLeft || root._barRight ? 12 : root._barOffset) : 0
    anchors.bottomMargin: root._barBottom ? root._barOffset : 0
    anchors.leftMargin: root._barLeft ? root._barOffset : 0
    anchors.rightMargin: !root._barLeft ? (root._barRight ? root._barOffset : 12) : 0
    width: 300
    height: column.implicitHeight + 24
    radius: Style.radiusXXS
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: 1

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: 12
      spacing: 10

      Text {
        text: "Sound"
        color: Color.mOnSurface
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 14
        font.bold: true
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
          width: 28
          height: 28
          radius: Style.radiusXXS
          color: hoverMute.hovered ? Color.alpha(Color.mPrimary, 0.16) : "transparent"
          border.color: Color.alpha(Color.mPrimary, 0.55)
          border.width: hoverMute.hovered ? 1 : 0
          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }

          Text {
            anchors.centerIn: parent
            text: root.muted ? "×" : "))"
            color: root.muted ? Color.mError : Color.mOnSurface
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: 13
          }

          HoverHandler {
            id: hoverMute
            cursorShape: Qt.PointingHandCursor
          }

          TapHandler {
            onTapped: if (root.sink && root.sink.audio)
              root.sink.audio.muted = !root.sink.audio.muted
          }
        }

        Slider {
          Layout.fillWidth: true
          from: 0
          to: 1.5
          value: root.volume
          onMoved: root.setVolume(value)
        }

        Text {
          text: Math.round(root.volume * 100) + "%"
          color: Color.mOnSurfaceVariant
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: 12
          Layout.preferredWidth: 34
        }
      }

      Text {
        text: "Output"
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 10
        Layout.topMargin: 4
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
          model: root.allSinks

          delegate: Rectangle {
            id: sinkRow
            required property var modelData
            Layout.fillWidth: true
            height: 32
            radius: Style.radiusXXS
            readonly property bool isDefault: root.sink && modelData.id === root.sink.id
            color: sinkRow.isDefault ? Color.alpha(Color.mPrimary, 0.16) : (hoverSink.hovered ? Color.alpha(Color.mPrimary, 0.12) : "transparent")
            border.color: Color.alpha(Color.mPrimary, 0.55)
            border.width: sinkRow.isDefault || hoverSink.hovered ? 1 : 0
            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8

              Text {
                text: sinkRow.isDefault ? "●" : "○"
                color: sinkRow.isDefault ? Color.mPrimary : Color.mOnSurfaceVariant
                font.family: Settings.data.ui.fontFamily
                font.pixelSize: 12
              }

              Text {
                text: sinkRow.modelData.description || sinkRow.modelData.name || ""
                color: Color.mOnSurface
                font.family: Settings.data.ui.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            HoverHandler {
              id: hoverSink
              cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
              onTapped: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
            }
          }
        }
      }
    }
  }
}
