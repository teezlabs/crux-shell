import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras

// User-configured button. Multi-instance: each reads its own widgetData entry.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false
  property var widgetData: ({})

  // A user-typed glyph, so font coverage is the user's call.
  readonly property string icon: widgetData.icon || ""
  readonly property string label: widgetData.label !== undefined ? widgetData.label : ""
  readonly property string leftCommand: widgetData.leftCommand || ""
  readonly property string rightCommand: widgetData.rightCommand || ""
  // Optional command whose stdout replaces the label, rerun every refreshMs.
  readonly property string textCommand: widgetData.textCommand || ""
  readonly property int refreshMs: {
    var v = widgetData.refreshMs !== undefined ? parseInt(widgetData.refreshMs) : NaN;
    return isNaN(v) || v < 250 ? 3000 : v;
  }

  property string dynamicText: ""
  readonly property string displayText: textCommand !== "" && dynamicText !== "" ? dynamicText : label

  Process {
    id: textProc
    stdout: StdioCollector {
      onStreamFinished: root.dynamicText = this.text.trim()
    }
    onExited: function () {}
  }

  function runTextCommand() {
    if (root.textCommand === "" || textProc.running)
      return;
    textProc.command = ["sh", "-lc", root.textCommand];
    textProc.running = true;
  }

  Timer {
    interval: root.refreshMs
    running: root.textCommand !== ""
    repeat: true
    triggeredOnStart: true
    onTriggered: root.runTextCommand()
  }

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
      spacing: root.icon !== "" && root.displayText !== "" ? 6 : 0

      NText {
        visible: root.icon !== ""
        text: root.icon
        color: Colors.surfaceText
        anchors.verticalCenter: parent.verticalCenter
      }

      NText {
        visible: root.displayText !== ""
        text: root.displayText
        color: Colors.surfaceText
        size: NText.Size.BodySm
        anchors.verticalCenter: parent.verticalCenter
      }

      // Placeholder so an unconfigured button is still visible and clickable.
      NText {
        visible: root.icon === "" && root.displayText === ""
        text: "+"
        color: Colors.surfaceTextMuted
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Column {
      visible: root.vertical
      spacing: 4
      NText {
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: root.icon !== "" ? root.icon : (root.displayText !== "" ? root.displayText.charAt(0) : "+")
        color: Colors.surfaceText
        size: NText.Size.LabelXs
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: {
      if (root.leftCommand !== "")
        Quickshell.execDetached(["sh", "-lc", root.leftCommand]);
      root.runTextCommand();
    }
  }

  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: {
      if (root.rightCommand !== "")
        Quickshell.execDetached(["sh", "-lc", root.rightCommand]);
      root.runTextCommand();
    }
  }
}
