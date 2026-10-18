import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Label and control with a fixed-width label column, so every control starts at the same x.
RowLayout {
  id: root

  property string label: ""
  property real labelWidth: 130
  default property alias content: contentRow.children

  spacing: 10
  Layout.fillWidth: true

  // Pinned with minimum and maximum, not preferredWidth alone (docs/qml-gotchas.md).
  NLabel {
    label: root.label
    labelColor: Colors.labelText
    wrap: false
    Layout.preferredWidth: root.labelWidth
    Layout.minimumWidth: root.labelWidth
    Layout.maximumWidth: root.labelWidth
  }

  RowLayout {
    id: contentRow
    spacing: 10
    Layout.fillWidth: true

    // The trailing description is the flexible item, so a long one elides instead of pushing the row past the card.
    Component.onCompleted: {
      const kids = contentRow.children;
      if (kids.length < 2)
        return;
      const last = kids[kids.length - 1];
      // `elide` only exists on Text, which is what a description is.
      if (!last || last.elide === undefined)
        return;
      last.Layout.fillWidth = true;
      // Descriptions wrap; NText's NoWrap + ElideRight default is for fixed strips.
      last.wrapMode = Text.WordWrap;
      last.elide = Text.ElideNone;
    }
  }
}
