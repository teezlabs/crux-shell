import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Bar.Extras

// Active keyboard layout of Keyboard.device; click cycles to the next layout.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property string currentLayout: Keyboard.layoutCode
  readonly property string fullLayoutName: Keyboard.layoutName

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    invertChamfer: root.invertChamfer
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 10

      StatText {
        label: "KBD"
        value: root.currentLayout
        valueColor: Colors.surfaceText
      }
    }

    Column {
      visible: root.vertical
      spacing: 8

      Column {
        width: 24
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: root.currentLayout
          color: Colors.surfaceText
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "KBD"
          color: Colors.labelText
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }
    }
  }

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: {
      if (hovered) {
        TooltipService.show(root, root.fullLayoutName || "Keyboard layout");
      } else {
        TooltipService.hide();
      }
    }
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: {
      TooltipService.hideImmediately();
      Keyboard.nextLayout();
    }
  }
}
