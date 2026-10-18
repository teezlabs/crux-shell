import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.ControlCenter
import qs.Widgets
import qs.Modules.Bar.Extras

// Opens the Control Center popup, a SlideCard in PopupHost, via the Popups registry.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false // true bar orientation (left/right bar)
  property bool invertChamfer: false

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8
    invertChamfer: root.invertChamfer

    Item {
      id: slot
      width: 24
      height: module.vertical ? measureCol.implicitHeight : 16

      // Invisible spacer matching Sound.qml's stacked-text metrics.
      Column {
        id: measureCol
        visible: module.vertical
        width: 24
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "00"
          opacity: 0
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "VOL"
          opacity: 0
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }

      ArchLogo {
        anchors.centerIn: parent
        width: 16
        height: 16
      }
    }
  }

  // Keeps the popup's folded size in sync with this module so it can collapse onto it.
  function pushMorphSource(): void {
    if (!root.screen)
      return;
    const pos = root.mapToItem(null, 0, 0);
    Popups.setMorphSource("controlCenter", root.screen, pos.x, pos.y, root.width, root.height);
  }

  // screen is assigned after construction, so push on every input the position depends on.
  Component.onCompleted: root.pushMorphSource()
  onScreenChanged: root.pushMorphSource()
  onWidthChanged: root.pushMorphSource()
  onHeightChanged: root.pushMorphSource()
  onXChanged: root.pushMorphSource()
  onYChanged: root.pushMorphSource()

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Popups.openFrom("controlCenter", root.screen, pos.x, pos.y, root.width, root.height);
    }
  }
}
