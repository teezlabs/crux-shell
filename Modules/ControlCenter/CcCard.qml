import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// One Control Center section as its own card; height comes from the inner layout, since an Item doesn't inherit it.
Item {
  id: root

  property real padding: Tokens.spaceLg
  property real spacing: Tokens.spaceMd
  default property alias content: inner.data

  Layout.fillWidth: true
  implicitHeight: inner.implicitHeight + root.padding * 2

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferModule
    cutTopRight: true
    cutBottomLeft: true
    fillColor: Colors.surfaceContainer
    strokeColor: Colors.outline
    strokeWidth: Tokens.borderModule
    shadow: true
    shadowBlur: Tokens.shadowBlurCard
    shadowOpacity: Tokens.shadowOpacityCard
    shadowOffset: Tokens.shadowOffsetCard
    rimLight: true
    rimOpacity: Tokens.rimOpacityCard
  }

  ColumnLayout {
    id: inner
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: root.spacing
  }
}
