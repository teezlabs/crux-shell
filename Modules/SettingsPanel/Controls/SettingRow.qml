import QtQuick
import QtQuick.Layouts
import qs.Commons

// Label + control row with a fixed-width label column so every row's
// control starts at the same x — the ad-hoc RowLayouts before this had
// labels of varying width shoving each row's slider/toggle to a different
// spot, which read as sloppy rather than deliberate.
RowLayout {
  id: root

  property string label: ""
  default property alias content: contentRow.children

  spacing: 10
  Layout.fillWidth: true

  Text {
    text: root.label
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeS
    Layout.preferredWidth: 130
  }

  RowLayout {
    id: contentRow
    spacing: 10
    Layout.fillWidth: true
  }
}
