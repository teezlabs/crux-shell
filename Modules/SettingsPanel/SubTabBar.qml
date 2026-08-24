import QtQuick
import QtQuick.Layouts
import qs.Commons

// Reusable horizontal pill-tab row for a top-level settings tab that has
// more than one logical page (e.g. Bar's "Layout"/"Widgets", Appearance's
// "General"/"Colors") — the second level of the Tab → SubTab navigation
// noctalia's settings panel uses. Tabs with only one page skip this
// entirely rather than showing a pointless single-pill bar.
RowLayout {
  id: root

  // [{id, label}]
  property var model: []
  property string activeId: model.length > 0 ? model[0].id : ""

  spacing: 4

  Repeater {
    model: root.model

    delegate: Rectangle {
      id: pill
      required property var modelData
      readonly property bool active: root.activeId === modelData.id
      Layout.preferredHeight: 26
      implicitWidth: label.implicitWidth + 20
      radius: Style.radiusXS
      color: active ? Color.mPrimary : (hoverHandler.hovered ? Color.mOutline : Color.mSurfaceVariant)

      Text {
        id: label
        anchors.centerIn: parent
        text: pill.modelData.label
        color: pill.active ? Color.mOnPrimary : Color.mOnSurface
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
      }

      HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
      }

      TapHandler {
        onTapped: root.activeId = pill.modelData.id
      }
    }
  }

  Item {
    Layout.fillWidth: true
  }
}
