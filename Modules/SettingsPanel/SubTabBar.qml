import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
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

    delegate: Item {
      id: pillWrap
      required property var modelData
      readonly property bool active: root.activeId === modelData.id
      Layout.preferredHeight: 26
      implicitWidth: label.implicitWidth + 20
      implicitHeight: 26

      MultiEffect {
        anchors.fill: pill
        source: pill
        shadowEnabled: pillWrap.active
        shadowColor: Color.mPrimary
        shadowBlur: 0.5
        shadowOpacity: 0.6
      }

      Rectangle {
        id: pill
        anchors.fill: parent
        radius: Style.radiusXS
        color: pillWrap.active ? Color.mPrimary : (hoverHandler.hovered ? Color.alpha(Color.mPrimary, 0.16) : Color.mSurfaceVariant)
        border.color: Color.alpha(Color.mPrimary, 0.55)
        border.width: !pillWrap.active && hoverHandler.hovered ? 1 : 0
        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }

        Text {
          id: label
          anchors.centerIn: parent
          text: pillWrap.modelData.label
          color: pillWrap.active ? Color.mOnPrimary : Color.mOnSurface
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
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
