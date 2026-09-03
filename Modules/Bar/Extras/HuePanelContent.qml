import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Real Hue brightness/color control UI, hosted in the hue popup PopupHost.qml manages.
// Pairing (bridge IP / link-button flow) lives in HueTab.qml under
// Settings instead, since that's a one-time setup step, not something
// worth surfacing every time the popup opens.
ColumnLayout {
  id: root

  spacing: 10

  readonly property var group: Hue.selectedGroup
  readonly property real brightness01: group ? group.brightness01 : 0

  RowLayout {
    Layout.fillWidth: true

    NText {
      tracking: true
      text: "HUE"
      color: Color.labelText
      size: NText.Size.LabelXs
      font.weight: Font.DemiBold
      Layout.fillWidth: true
    }

    NText {
      visible: root.group !== null
      text: root.group ? root.group.name : ""
      color: Color.labelText
      size: NText.Size.Caption
    }
  }

  NText {
    visible: !Hue.paired
    text: "Not paired — configure in Settings → Hue."
    color: Color.labelText
    size: NText.Size.BodySm
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  NText {
    visible: Hue.paired && !root.group
    text: "No room/zone selected — pick one in Settings → Hue."
    color: Color.labelText
    size: NText.Size.BodySm
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 10
    visible: Hue.paired && root.group !== null

    NToggle {
      checked: !!(root.group && root.group.on)
      onToggled: checked => {
                   if (root.group)
                   root.group.setOn(checked);
                 }
    }

    NSlider {
      Layout.fillWidth: true
      from: 0
      to: 1
      value: root.brightness01
      stepSize: 0.01
      onMoved: value => {
                 if (root.group)
                 root.group.setBrightness(value);
               }
    }

    NText {
      text: root.group ? Math.round(root.brightness01 * 100) + "%" : ""
      color: Color.labelText
      size: NText.Size.BodySm
      Layout.preferredWidth: 34
    }
  }

  Row {
    id: colorSwatchRow
    spacing: 10
    visible: Hue.paired && root.group !== null

    property int diameter: 22

    Repeater {
      model: [Color.primary, Color.tertiary, Color.error, Color.surfaceText]

      Rectangle {
        width: colorSwatchRow.diameter
        height: colorSwatchRow.diameter
        radius: 0
        color: modelData
        border.width: root.group && root.group.lastColor.toString() === modelData.toString() ? 2 : 1
        border.color: root.group && root.group.lastColor.toString() === modelData.toString() ? Color.surfaceText : Color.outline

        HoverHandler {
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: {
            if (root.group)
              root.group.setColor(modelData);
          }
        }
      }
    }
  }
}
