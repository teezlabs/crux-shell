import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Commons

// Volume popup content: default-output volume slider + mute toggle, and a
// list of available output devices to switch the default sink. Hosted
// inside a SlideCard by PopupHost.qml — no window/positioning of its own.
ColumnLayout {
  id: root

  spacing: 12

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

  function setVolume(pct) {
    if (!root.sink || !root.sink.audio)
      return;
    root.sink.audio.volume = pct / 100;
    if (pct > 0)
      root.sink.audio.muted = false;
  }

  Text {
    text: "SOUND"
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.labelXsSize
    font.weight: Font.DemiBold
    font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 10

    Item {
      width: 28
      height: 28

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferIcon
        cutTopRight: true
        cutBottomLeft: true
        fillColor: hoverMute.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
        strokeColor: root.muted ? Color.alpha(Color.error, Tokens.destructiveBorderAlpha) : Color.outline
        strokeWidth: Tokens.borderModule
      }

      Text {
        anchors.centerIn: parent
        text: root.muted ? "×" : "))"
        color: root.muted ? Color.error : Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
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

    SegMeter {
      Layout.fillWidth: true
      cellCount: Tokens.meterControlCenterCells
      cellHeight: Tokens.meterControlCenterCellHeight
      value: root.muted ? 0 : root.volume * 100
      interactive: true
      filledColor: Color.primary
      emptyColor: Color.surfaceContainerHigh
      onMoved: pct => root.setVolume(pct)
    }

    Text {
      text: root.muted ? "—" : Math.round(root.volume * 100) + "%"
      color: root.muted ? Color.error : Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
      Layout.preferredWidth: 34
    }
  }

  Text {
    text: "OUTPUT"
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.labelXsSize
    font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
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
        readonly property bool isDefault: root.sink && modelData.id === root.sink.id
        color: sinkRow.isDefault ? Color.primaryContainer : (hoverSink.hovered ? Color.surfaceContainerHigh : "transparent")

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8

          Text {
            text: sinkRow.isDefault ? "●" : "○"
            color: sinkRow.isDefault ? Color.primary : Color.labelText
            font.pixelSize: Tokens.bodySmSize
          }

          Text {
            text: sinkRow.modelData.description || sinkRow.modelData.name || ""
            color: sinkRow.isDefault ? Color.primaryContainerText : Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
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
