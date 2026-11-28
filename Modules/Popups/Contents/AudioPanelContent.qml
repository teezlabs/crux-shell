import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.ControlCenter
import qs.Modules.Popups
import qs.Widgets

// Audio page for the Control Center: output and input volume, and every device to switch between.
ColumnLayout {
  id: root

  // Shown as a Control Center sub-page: the header gets a back arrow.
  property bool showBack: false
  signal backRequested
  // The device lists scroll past this height.
  property real maxListHeight: 480

  spacing: Tokens.spaceLg

  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property var source: Pipewire.ready ? Pipewire.defaultAudioSource : null
  readonly property var nodes: Pipewire.ready && Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property var sinks: root.nodes.filter(n => n && n.audio && n.isSink && !n.isStream)
  readonly property var sources: root.nodes.filter(n => n && n.audio && !n.isSink && !n.isStream)

  PwObjectTracker {
    objects: root.sinks.concat(root.sources)
  }

  function deviceName(node) {
    return node ? (node.description || node.nickname || node.name || "") : "";
  }

  // Guesses the device kind from PipeWire's name and description.
  function deviceSymbol(node, isOutput) {
    const text = (root.deviceName(node) + " " + (node ? node.name : "")).toLowerCase();
    if (text.indexOf("hdmi") !== -1 || text.indexOf("displayport") !== -1)
      return "tv";
    if (text.indexOf("headphone") !== -1 || text.indexOf("headset") !== -1 || text.indexOf("arctis") !== -1 || text.indexOf("bluez") !== -1)
      return "headphones";
    return isOutput ? "speaker" : "mic";
  }

  PopupHeader {
    title: "AUDIO"
    showBack: root.showBack
    onBackTapped: root.backRequested()
  }

  NScrollView {
    id: scroll
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(cards.implicitHeight, root.maxListHeight)
    contentHeight: cards.implicitHeight

    ColumnLayout {
      id: cards
      width: scroll.width - (scroll.scrollable ? scroll.gutter : 0)
      spacing: Tokens.spaceMd

      Repeater {
        model: [
          {
            "output": true
          },
          {
            "output": false
          }
        ]

        delegate: NetSection {
          id: section
          required property var modelData
          readonly property bool isOutput: modelData.output
          readonly property var node: section.isOutput ? root.sink : root.source
          readonly property bool muted: !!(section.node && section.node.audio && section.node.audio.muted)
          readonly property real pct: section.node && section.node.audio && !section.muted ? section.node.audio.volume * 100 : 0
          readonly property var devices: section.isOutput ? root.sinks : root.sources

          label: section.isOutput ? "OUTPUT" : "INPUT"
          active: !!section.node

          RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.spaceXs
            Layout.bottomMargin: Tokens.spaceSm
            spacing: Tokens.spaceMd

            CcIconButton {
              size: 32
              symbol: section.isOutput ? (section.muted ? "volume_off" : "volume_up") : (section.muted ? "mic_off" : "mic")
              tooltip: section.muted ? "Unmute" : "Mute"
              tone: section.muted ? "error" : ""
              available: !!section.node
              onTapped: if (section.node && section.node.audio)
                section.node.audio.muted = !section.node.audio.muted
            }
            CcLevelSlider {
              Layout.fillWidth: true
              value: section.pct
              interactive: !!section.node
              onMoved: pct => {
                if (!section.node || !section.node.audio)
                  return;
                section.node.audio.volume = pct / 100;
                if (pct > 0)
                  section.node.audio.muted = false;
              }
            }
            NText {
              Layout.preferredWidth: 40
              Layout.minimumWidth: 40
              Layout.maximumWidth: 40
              horizontalAlignment: Text.AlignRight
              text: Math.round(section.pct) + "%"
              size: NText.Size.Caption
              color: Colors.surfaceTextMuted
              font.features: {
                "tnum": 1
              }
            }
          }

          NText {
            visible: section.devices.length === 0
            Layout.fillWidth: true
            Layout.margins: Tokens.spaceSm
            text: section.isOutput ? "No output devices" : "No input devices"
            size: NText.Size.Caption
            color: Colors.labelText
          }

          Repeater {
            model: section.devices

            delegate: NetRow {
              required property var modelData
              readonly property bool isDefault: !!section.node && modelData.id === section.node.id
              symbol: root.deviceSymbol(modelData, section.isOutput)
              highlighted: isDefault
              title: root.deviceName(modelData)
              subtitle: isDefault ? "In use" : "Tap to switch"
              onTapped: {
                if (section.isOutput)
                  Pipewire.preferredDefaultAudioSink = modelData;
                else
                  Pipewire.preferredDefaultAudioSource = modelData;
              }
            }
          }
        }
      }
    }
  }
}
