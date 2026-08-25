import QtQuick
import QtQuick.Layouts
import qs.Commons

// Grouped-card section wrapper — noctalia groups related settings rows
// inside a bordered card (NBox) with a title above it; this is crux's own
// lean version of that, used to turn a flat wall of label/control rows
// into visually distinct, scannable groups.
ColumnLayout {
  id: root

  property string title: ""
  property string description: ""
  default property alias content: inner.children

  spacing: 6
  Layout.fillWidth: true

  Text {
    visible: root.title !== ""
    text: root.title
    color: Color.mOnSurface
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeM
    font.bold: true
    Layout.bottomMargin: 2
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
    Layout.preferredHeight: inner.implicitHeight + 24
    radius: Style.radiusS
    color: Color.mSurfaceVariant
    border.color: Color.mOutline
    border.width: 1

    ColumnLayout {
      id: inner
      anchors.fill: parent
      anchors.margins: 12
      spacing: 14
    }
  }
}
