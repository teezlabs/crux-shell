import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Widgets
import qs.Modules.Popups

// Volume popup content: default-output volume slider + mute toggle, and a
// list of available output devices to switch the default sink. Hosted
// inside a SlideCard by PopupHost.qml — no window/positioning of its own.
ColumnLayout {
  id: root

  spacing: Tokens.spaceLg

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

  PopupHeader {
    title: "SOUND"
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
        fillColor: hoverMute.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
        strokeColor: root.muted ? Colors.alpha(Colors.error, Tokens.destructiveBorderAlpha) : Colors.outline
        strokeWidth: Tokens.borderModule
      }

      NText {
        anchors.centerIn: parent
        text: root.muted ? "×" : "))"
        color: root.muted ? Colors.error : Colors.surfaceText
        size: NText.Size.BodySm
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
      filledColor: Colors.primary
      emptyColor: Colors.surfaceContainerHigh
      onMoved: pct => root.setVolume(pct)
    }

    NText {
      text: root.muted ? "—" : Math.round(root.volume * 100) + "%"
      color: root.muted ? Colors.error : Colors.labelText
      size: NText.Size.BodySm
      Layout.preferredWidth: 34
    }
  }

  NText {
    tracking: true
    text: "OUTPUT"
    color: Colors.labelText
    size: NText.Size.LabelXs
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
        color: sinkRow.isDefault ? Colors.primaryContainer : (hoverSink.hovered ? Colors.surfaceContainerHigh : "transparent")

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Tokens.spaceMd
          anchors.rightMargin: Tokens.spaceMd

          Text {
            text: sinkRow.isDefault ? "●" : "○"
            color: sinkRow.isDefault ? Colors.primary : Colors.labelText
            font.pixelSize: Tokens.bodySmSize
          }

          NText {
            text: sinkRow.modelData.description || sinkRow.modelData.name || ""
            color: sinkRow.isDefault ? Colors.primaryContainerText : Colors.surfaceText
            size: NText.Size.BodySm
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
