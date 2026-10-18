import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Bar.Extras

// Pending package count from UpdatesService; click runs the update when there is one, else rechecks.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property int updateCount: UpdatesService.updateCount
  readonly property bool checking: UpdatesService.checking
  readonly property bool hasUpdates: updateCount > 0
  readonly property bool shouldHide: Settings.data.updates.hideOnZero && updateCount === 0

  function countdownLabel(): string {
    const s = Math.max(0, Math.round((UpdatesService.nextCheckAt - Date.now()) / 1000));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  Component.onCompleted: UpdatesService.watchers++
  Component.onDestruction: UpdatesService.watchers--

  // Size goes to 0 too: BarSection lays out by implicit size, and visible alone leaves a gap.
  implicitWidth: root.shouldHide ? 0 : module.implicitWidth
  implicitHeight: root.shouldHide ? 0 : module.implicitHeight
  width: implicitWidth
  height: implicitHeight
  visible: !root.shouldHide

  BarModule {
    id: module
    vertical: root.vertical
    invertChamfer: root.invertChamfer
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 10

      StatText {
        label: "UPD"
        value: root.updateCount < 0 ? "…" : String(root.updateCount)
        valueColor: root.hasUpdates ? Colors.tertiary : Colors.surfaceTextMuted
      }
    }

    Column {
      visible: root.vertical
      spacing: 8

      Column {
        width: 24
        Text {
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: root.updateCount < 0 ? "…" : String(root.updateCount)
          color: root.hasUpdates ? Colors.tertiary : Colors.surfaceTextMuted
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
        Text {
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "UPD"
          color: Colors.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: {
      if (hovered) {
        let msg = root.checking ? "Checking…" : (root.hasUpdates ? root.updateCount + " updates pending" : "No updates pending");
        msg += " · next check in " + root.countdownLabel();
        msg += "\nRight-click: settings";
        TooltipService.show(root, msg);
      } else {
        TooltipService.hide();
      }
    }
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: root.hasUpdates ? UpdatesService.runUpdate() : UpdatesService.check()
  }
  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: {
      TooltipService.hideImmediately();
      Popups.openTab("settings", root.screen, "updates");
    }
  }
}
