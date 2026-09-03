import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// User-configurable button: icon, label, left/right click commands, optional refreshed text command.
// Multi-instance: each button reads its own widgetData entry, not a shared Settings singleton (see BarWidgetRegistry.multiInstanceIds).
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property var widgetData: ({})

  // Icon is a plain user-typed glyph, not one of crux's own icon-theme
  // lookups — fine here since it's user-supplied config, not built-in
  // chrome (which never depends on font/emoji glyph coverage, see other
  // widgets' Canvas-drawn icons).
  readonly property string icon: widgetData.icon || ""
  readonly property string label: widgetData.label !== undefined ? widgetData.label : ""
  readonly property string leftCommand: widgetData.leftCommand || ""
  readonly property string rightCommand: widgetData.rightCommand || ""
  // Optional: periodically-run command whose stdout replaces the label —
  // a lightweight version of noctalia's textCommand (no JSON/streaming).
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
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: root.icon !== "" && root.displayText !== "" ? 6 : 0

      NText {
        visible: root.icon !== ""
        text: root.icon
        color: Color.surfaceText
        anchors.verticalCenter: parent.verticalCenter
      }

      NText {
        visible: root.displayText !== ""
        text: root.displayText
        color: Color.surfaceText
        size: NText.Size.BodySm
        anchors.verticalCenter: parent.verticalCenter
      }

      // Placeholder so an unconfigured button is still visible/clickable
      // — plain ASCII, no font/emoji glyph dependency.
      NText {
        visible: root.icon === "" && root.displayText === ""
        text: "+"
        color: Color.surfaceTextMuted
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
        color: Color.surfaceText
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
