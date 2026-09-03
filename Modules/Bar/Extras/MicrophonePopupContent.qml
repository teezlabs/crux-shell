import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Widgets

// Microphone popup content: default-input volume slider + mute toggle, and
// a list of available input devices to switch the default source. Exact
// structural mirror of SoundPopupContent.qml, just bound to
// defaultAudioSource/allSources. Hosted inside a SlideCard by
// PopupHost.qml — no window/positioning of its own.
ColumnLayout {
  id: root

  spacing: 12

  readonly property var source: Pipewire.ready ? Pipewire.defaultAudioSource : null
  readonly property real volume: source && source.audio ? source.audio.volume : 0
  readonly property bool muted: source && source.audio ? source.audio.muted : false

  readonly property var allSources: {
    if (!Pipewire.ready || !Pipewire.nodes)
      return [];
    return Pipewire.nodes.values.filter(function (n) {
      return n && !n.isSink && !n.isStream && n.audio;
    });
  }

  PwObjectTracker {
    objects: root.source ? [root.source] : []
  }

  function setVolume(pct) {
    if (!root.source || !root.source.audio)
      return;
    root.source.audio.volume = pct / 100;
    if (pct > 0)
      root.source.audio.muted = false;
  }

  NText {
    tracking: true
    text: "MICROPHONE"
    color: Color.labelText
    size: NText.Size.LabelXs
    font.weight: Font.DemiBold
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

      NText {
        anchors.centerIn: parent
        text: root.muted ? "×" : "))"
        color: root.muted ? Color.error : Color.surfaceText
        size: NText.Size.BodySm
      }

      HoverHandler {
        id: hoverMute
        cursorShape: Qt.PointingHandCursor
      }

      TapHandler {
        onTapped: if (root.source && root.source.audio)
          root.source.audio.muted = !root.source.audio.muted
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

    NText {
      text: root.muted ? "—" : Math.round(root.volume * 100) + "%"
      color: root.muted ? Color.error : Color.labelText
      size: NText.Size.BodySm
      Layout.preferredWidth: 34
    }
  }

  NText {
    tracking: true
    text: "INPUT"
    color: Color.labelText
    size: NText.Size.LabelXs
    Layout.topMargin: 4
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 2

    Repeater {
      model: root.allSources

      delegate: Rectangle {
        id: sourceRow
        required property var modelData
        Layout.fillWidth: true
        height: 32
        readonly property bool isDefault: root.source && modelData.id === root.source.id
        color: sourceRow.isDefault ? Color.primaryContainer : (hoverSource.hovered ? Color.surfaceContainerHigh : "transparent")

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8

          Text {
            text: sourceRow.isDefault ? "●" : "○"
            color: sourceRow.isDefault ? Color.primary : Color.labelText
            font.pixelSize: Tokens.bodySmSize
          }

          NText {
            text: sourceRow.modelData.description || sourceRow.modelData.name || ""
            color: sourceRow.isDefault ? Color.primaryContainerText : Color.surfaceText
            size: NText.Size.BodySm
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }

        HoverHandler {
          id: hoverSource
          cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
          onTapped: Pipewire.preferredDefaultAudioSource = sourceRow.modelData
        }
      }
    }

    NText {
      visible: root.allSources.length === 0
      text: "No input devices found."
      color: Color.labelText
      size: NText.Size.BodySm
    }
  }
}
