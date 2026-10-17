import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Widgets
import qs.Modules.Popups

// Microphone popup content: default-input volume slider + mute toggle, and
// a list of available input devices to switch the default source. Exact
// structural mirror of SoundPopupContent.qml, just bound to
// defaultAudioSource/allSources. Hosted inside a SlideCard by
// PopupHost.qml — no window/positioning of its own.
ColumnLayout {
  id: root

  spacing: Tokens.spaceLg

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

  PopupHeader {
    title: "MICROPHONE"
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
    text: "INPUT"
    color: Colors.labelText
    size: NText.Size.LabelXs
    Layout.topMargin: 4
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 2

    Repeater {
      model: root.allSources

      delegate: Item {
        id: sourceRow
        required property var modelData
        Layout.fillWidth: true
        height: Tokens.rowHeight
        readonly property bool isDefault: root.source && modelData.id === root.source.id

        PopupRowBackground {
          hovered: hoverSource.hovered
          selected: sourceRow.isDefault
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Tokens.spaceMd
          anchors.rightMargin: Tokens.spaceMd

          NText {
            text: sourceRow.isDefault ? "●" : "○"
            color: sourceRow.isDefault ? Colors.primary : Colors.labelText
            size: NText.Size.BodySm
          }

          NText {
            text: sourceRow.modelData.description || sourceRow.modelData.name || ""
            color: Colors.surfaceText
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
      color: Colors.labelText
      size: NText.Size.BodySm
    }
  }
}
