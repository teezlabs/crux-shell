import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.SettingsPanel.Controls

ColumnLayout {
  id: root
  spacing: 20

  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
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

  SettingsSection {
    title: "Volume"

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
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
      }
    }

    Text {
      text: "Per scroll notch on the bar's Sound icon, and per hardware volume key press."
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeXS
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }

  SettingsSection {
    title: "Output devices"

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
              font.pixelSize: Style.fontSizeM
            }

            Text {
              text: sinkRow.modelData.description || sinkRow.modelData.name || ""
              color: Color.mOnSurface
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: Style.fontSizeS
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              visible: sinkRow.modelData.audio
              text: sinkRow.modelData.audio ? Math.round(sinkRow.modelData.audio.volume * 100) + "%" : ""
              color: Color.mOnSurfaceVariant
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: Style.fontSizeS
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
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
