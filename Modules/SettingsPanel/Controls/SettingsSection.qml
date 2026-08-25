import QtQuick
import QtQuick.Layouts
import qs.Commons

// Grouped-card section wrapper. Title reads as a HUD-style label (accent
// tick + letter-spaced uppercase + trailing gradient rule) rather than
// plain bold text, and the card itself gets a faint top-lit gradient and a
// primary-tinted border instead of a flat mOutline box — small cues meant
// to read as "designed", not just "grouped".
ColumnLayout {
  id: root

  property string title: ""
  property string description: ""
  default property alias content: inner.children

  spacing: 8
  Layout.fillWidth: true

  RowLayout {
    visible: root.title !== ""
    spacing: 8
    Layout.bottomMargin: 2

    Rectangle {
      width: 3
      height: 13
      radius: 1.5
      color: Color.mPrimary
    }

    Text {
      text: root.title.toUpperCase()
      color: Color.mOnSurface
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      font.bold: true
      font.letterSpacing: 1.5
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
          position: 0
          color: Color.alpha(Color.mPrimary, 0.35)
        }
        GradientStop {
          position: 1
          color: "transparent"
        }
      }
    }
  }

  Text {
    visible: root.description !== ""
    text: root.description
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeXS
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Layout.bottomMargin: 4
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: inner.implicitHeight + 26
    radius: Style.radiusS
    border.color: Color.alpha(Color.mPrimary, 0.28)
    border.width: 1

    gradient: Gradient {
      GradientStop {
        position: 0
        color: Qt.lighter(Color.mSurfaceVariant, 1.08)
      }
      GradientStop {
        position: 1
        color: Color.mSurfaceVariant
      }
    }

    ColumnLayout {
      id: inner
      anchors.fill: parent
      anchors.margins: 14
      spacing: 14
    }
  }
}
