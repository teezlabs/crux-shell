import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Label + control row with a fixed-width label column so every row's
// control starts at the same x.
RowLayout {
  id: root

  property string label: ""
  property real labelWidth: 130
  default property alias content: contentRow.children

  spacing: 10
  Layout.fillWidth: true

  // Pinned with minimum and maximum, not preferredWidth alone. preferred is
  // only a hint: next to a fillWidth sibling the label was treated as the
  // flexible item and got whatever the controls left over, measured at 254,
  // 0, 91 and 343 across four rows of one section — so no two rows started
  // their control at the same x. Same trap as the sidebar in
  // SettingsWindow; see the crux skill.
  NLabel {
    label: root.label
    labelColor: Color.labelText
    wrap: false
    Layout.preferredWidth: root.labelWidth
    Layout.minimumWidth: root.labelWidth
    Layout.maximumWidth: root.labelWidth
  }

  RowLayout {
    id: contentRow
    spacing: 10
    Layout.fillWidth: true

    // Rows are control-then-description. Once the label column stopped
    // collapsing to absorb the overflow, a long description pushed the row
    // past the card's right edge and got clipped instead of elided, because
    // nothing in the row was allowed to shrink. Marking the trailing text
    // as the flexible one fixes every row at once rather than needing
    // Layout.fillWidth added at two dozen call sites.
    Component.onCompleted: {
      const kids = contentRow.children;
      if (kids.length < 2)
        return;
      const last = kids[kids.length - 1];
      // `elide` only exists on Text, which is what a description is.
      if (!last || last.elide === undefined)
        return;
      last.Layout.fillWidth = true;
      // Wrap onto another line rather than truncating. NText defaults to
      // NoWrap + ElideRight, which is right for a bar widget with a fixed
      // strip to live in, and wrong for a settings description that simply
      // needs to be readable.
      last.wrapMode = Text.WordWrap;
      last.elide = Text.ElideNone;
    }
  }
}
