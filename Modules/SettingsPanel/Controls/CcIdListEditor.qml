import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Ordered editor for one Control Center id list (Settings.data.controlCenter[key]): reorder, remove, add from a registry.
ColumnLayout {
  id: root

  // "toggles" or "shortcuts".
  property string key: ""
  // A CcToggleRegistry or CcShortcutRegistry: needs `ids` and `labelFor(id)`.
  property var registry: null
  property string emptyText: ""

  readonly property var list: Settings.data.controlCenter[root.key] || []

  Layout.fillWidth: true
  spacing: 6

  Repeater {
    model: root.list

    delegate: RowLayout {
      id: row
      required property string modelData
      required property int index
      Layout.fillWidth: true
      spacing: 6

      NSymbol {
        visible: name !== ""
        name: root.registry && root.registry.symbolFor ? root.registry.symbolFor(row.modelData) : ""
        size: 16
        color: Colors.surfaceTextMuted
      }
      NText {
        text: root.registry ? root.registry.labelFor(row.modelData) : row.modelData
        color: Colors.surfaceText
        size: NText.Size.BodySm
        Layout.fillWidth: true
      }
      NButton {
        text: "↑"
        horizontalPadding: 8
        enabled: row.index > 0
        onClicked: Settings.moveCcItem(root.key, row.index, -1)
      }
      NButton {
        text: "↓"
        horizontalPadding: 8
        enabled: row.index < root.list.length - 1
        onClicked: Settings.moveCcItem(root.key, row.index, 1)
      }
      NButton {
        text: "Remove"
        variant: "destructive"
        onClicked: Settings.removeCcItem(root.key, row.index)
      }
    }
  }

  NText {
    visible: root.list.length === 0
    text: root.emptyText
    color: Colors.labelText
    size: NText.Size.Caption
  }

  NText {
    tracking: true
    text: "ADD"
    color: Colors.labelText
    size: NText.Size.LabelXs
    Layout.topMargin: 4
  }

  Flow {
    Layout.fillWidth: true
    spacing: 4

    Repeater {
      model: root.registry ? root.registry.ids : []

      delegate: NButton {
        required property string modelData
        text: root.registry.labelFor(modelData)
        textSize: NText.Size.LabelXs
        horizontalPadding: 8
        implicitHeight: 22
        enabled: root.list.indexOf(modelData) === -1
        onClicked: Settings.addCcItem(root.key, modelData)
      }
    }
  }
}
