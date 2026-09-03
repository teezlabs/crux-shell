import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Label + control row with a fixed-width label column so every row's
// control starts at the same x.
RowLayout {
  id: root

  property string label: ""
  default property alias content: contentRow.children

  spacing: 10
  Layout.fillWidth: true

  NText {
    text: root.label
    color: Color.labelText
    size: NText.Size.BodySm
    Layout.preferredWidth: 130
  }

  RowLayout {
    id: contentRow
    spacing: 10
    Layout.fillWidth: true
  }
}
