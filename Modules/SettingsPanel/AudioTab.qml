import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls

Flickable {
  id: root
  clip: true
  contentWidth: width
  contentHeight: col.implicitHeight

  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property var source: Pipewire.ready ? Pipewire.defaultAudioSource : null
  readonly property var allSinks: {
    if (!Pipewire.ready || !Pipewire.nodes)
      return [];
    return Pipewire.nodes.values.filter(function (n) {
      return n && n.isSink && !n.isStream;
    });
  }
  // A "source" (mic/input) is any non-stream, non-sink node that still has
  // an .audio property — same filter noctalia's AudioService.qml uses,
  // since Pipewire doesn't expose a plain isSource flag.
  readonly property var allSources: {
    if (!Pipewire.ready || !Pipewire.nodes)
      return [];
    return Pipewire.nodes.values.filter(function (n) {
      return n && !n.isSink && !n.isStream && n.audio;
    });
  }

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }
  PwObjectTracker {
    objects: root.source ? [root.source] : []
  }

  readonly property var mprisPlayers: Mpris.players ? Mpris.players.values : []

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Volume"
    description: "How much each step changes the volume by."

    SettingRow {
      label: "Scroll step"
      NSlider {
        Layout.preferredWidth: 200
        from: 0.01
        to: 0.2
        stepSize: 0.01
        value: Settings.data.audio.step
        onMoved: value => Settings.data.audio.step = value
      }
      Text {
        text: Math.round(Settings.data.audio.step * 100) + "%"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    Text {
      text: "Per scroll notch on the bar's Status module, and per hardware volume key press."
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    SettingRow {
      label: "Overdrive"
      NToggle {
        checked: Settings.data.audio.volumeOverdrive
        onToggled: checked => Settings.data.audio.volumeOverdrive = checked
      }
      Text {
        text: "Lets scroll/hardware keys push volume up to 150% — the Sound popup's own slider still caps at 100%."
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }
  }

  SettingsSection {
    title: "Output devices"
    description: "Pick which speaker or headset gets audio by default."

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      Repeater {
        model: root.allSinks

        delegate: Rectangle {
          id: sinkRow
          required property var modelData
          Layout.fillWidth: true
          height: 34
          readonly property bool isDefault: root.sink && modelData.id === root.sink.id
          color: sinkRow.isDefault ? Color.primaryContainer : (hoverSink.hovered ? Color.surfaceContainerHigh : "transparent")

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            Text {
              text: sinkRow.isDefault ? "●" : "○"
              color: sinkRow.isDefault ? Color.primary : Color.labelText
              font.pixelSize: Tokens.bodySize
            }

            Text {
              text: sinkRow.modelData.description || sinkRow.modelData.name || ""
              color: sinkRow.isDefault ? Color.primaryContainerText : Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              visible: sinkRow.modelData.audio
              text: sinkRow.modelData.audio ? Math.round(sinkRow.modelData.audio.volume * 100) + "%" : ""
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
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

      Text {
        visible: root.allSinks.length === 0
        text: "No output devices found."
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }

  SettingsSection {
    title: "Input devices"
    description: "Pick which microphone is used by default."

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      Repeater {
        model: root.allSources

        delegate: Rectangle {
          id: sourceRow
          required property var modelData
          Layout.fillWidth: true
          height: 34
          readonly property bool isDefault: root.source && modelData.id === root.source.id
          color: sourceRow.isDefault ? Color.primaryContainer : (hoverSource.hovered ? Color.surfaceContainerHigh : "transparent")

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            Text {
              text: sourceRow.isDefault ? "●" : "○"
              color: sourceRow.isDefault ? Color.primary : Color.labelText
              font.pixelSize: Tokens.bodySize
            }

            Text {
              text: sourceRow.modelData.description || sourceRow.modelData.name || ""
              color: sourceRow.isDefault ? Color.primaryContainerText : Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              visible: sourceRow.modelData.audio
              text: sourceRow.modelData.audio ? Math.round(sourceRow.modelData.audio.volume * 100) + "%" : ""
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
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

      Text {
        visible: root.allSources.length === 0
        text: "No input devices found."
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }

  SettingsSection {
    title: "Media"
    description: "Which MPRIS player the bar's media widget and popover show, when more than one is active."

    Flow {
      Layout.fillWidth: true
      spacing: 4

      Repeater {
        model: {
          var list = [{
              "id": "",
              "label": "Auto"
            }];
          var seen = {};
          for (var i = 0; i < root.mprisPlayers.length; i++) {
            var p = root.mprisPlayers[i];
            if (p && p.identity && !seen[p.identity]) {
              seen[p.identity] = true;
              list.push({
                "id": p.identity,
                "label": p.identity
              });
            }
          }
          return list;
        }

        delegate: Item {
          id: playerPill
          required property var modelData
          readonly property bool selected: Settings.data.audio.preferredMediaPlayer === modelData.id
          width: playerLabel.implicitWidth + 20
          height: 26

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: playerPill.selected ? Color.primaryContainer : Color.surfaceContainer
            strokeColor: playerPill.selected ? Color.primary : Color.outline
            strokeWidth: Tokens.borderModule
          }

          Text {
            id: playerLabel
            anchors.centerIn: parent
            text: playerPill.modelData.label
            color: playerPill.selected ? Color.primaryContainerText : Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: Settings.data.audio.preferredMediaPlayer = playerPill.modelData.id
          }
        }
      }
    }

    Text {
      visible: root.mprisPlayers.length === 0
      text: "No MPRIS players currently detected — open one to pick it here."
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }
  }
}
