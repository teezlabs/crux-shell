import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras

// Reusable horizontal pill-tab row for a top-level settings tab that has
// more than one logical page (e.g. Bar's "Layout"/"Widgets"). v2 style:
// chamfered pill (radius: 0, no glow per hard rules 1/4), primaryContainer
// fill when active.
RowLayout {
  id: root

  // [{id, label}]
  property var model: []
  property string activeId: model.length > 0 ? model[0].id : ""

  spacing: 4

  Repeater {
    model: root.model

    delegate: Item {
      id: pillWrap
      required property var modelData
      readonly property bool active: root.activeId === modelData.id
      Layout.preferredHeight: 26
      implicitWidth: label.implicitWidth + 20
      implicitHeight: 26

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferIcon
        cutTopRight: true
        cutBottomLeft: true
        fillColor: pillWrap.active ? Color.primaryContainer : (hoverHandler.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
        strokeColor: pillWrap.active ? Color.primary : Color.outline
        strokeWidth: Tokens.borderModule

        Text {
          id: label
          anchors.centerIn: parent
          text: pillWrap.modelData.label.toUpperCase()
          color: pillWrap.active ? Color.primaryContainerText : Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.weight: Font.DemiBold
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }

      HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
      }

      TapHandler {
        onTapped: root.activeId = pillWrap.modelData.id
      }
    }
  }

  Item {
    Layout.fillWidth: true
  }
}
