import QtQuick
import QtQuick.Layouts
import qs.Commons

// Horizontal chamfered pill-tab row. Model is [{id, label}].
RowLayout {
  id: root

  property var model: []
  property string activeId: model.length > 0 ? model[0].id : ""
  property real tabHeight: 26

  signal activated(string id)

  spacing: 4

  Repeater {
    model: root.model

    delegate: Item {
      id: pill
      required property var modelData
      readonly property bool active: root.activeId === modelData.id

      Layout.preferredHeight: root.tabHeight
      implicitWidth: pillLabel.implicitWidth + 20
      implicitHeight: root.tabHeight

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferIcon
        cutTopRight: true
        cutBottomLeft: true
        fillColor: pill.active ? Color.primaryContainer : (pillHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
        strokeColor: pill.active ? Color.primary : Color.outline
        strokeWidth: Tokens.borderModule
      }

      NText {
        id: pillLabel
        anchors.centerIn: parent
        text: pill.modelData.label.toUpperCase()
        size: NText.Size.LabelXs
        tracking: true
        color: pill.active ? Color.primaryContainerText : Color.surfaceText
      }

      HoverHandler {
        id: pillHover
        cursorShape: Qt.PointingHandCursor
      }
      TapHandler {
        onTapped: {
          root.activeId = pill.modelData.id;
          root.activated(pill.modelData.id);
        }
      }
    }
  }

  Item {
    Layout.fillWidth: true
  }
}
