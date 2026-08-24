import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs.Commons

// Polkit authentication agent. This machine has none currently running
// (Hyprland's config references "hyprpolkitagent" via systemd, but that
// unit doesn't exist here — confirmed directly: `pkexec` calls fail
// silently with no agent to show a prompt). Fixing that only improves
// things — there's no working agent to conflict with or regress.
//
// API (PolkitAgent { path }, flow.message/inputPrompt/isResponseRequired/
// submit()/cancelAuthenticationRequest()) confirmed from Omarchy's real
// shell/plugins/polkit/PolkitAgent.qml; UI rebuilt plain (no icon-font
// glyphs, no fingerprint/lid-detection — this box has no laptop battery).
Item {
  id: root

  property bool submitted: false
  property bool failed: false
  property string message: ""
  property string prompt: ""

  readonly property bool dialogVisible: agent.isActive

  PolkitAgent {
    id: agent
    path: "/org/crux/PolkitAgent"

    onAuthenticationRequestStarted: {
      root.submitted = false;
      root.failed = false;
      syncFromFlow();
      Qt.callLater(function () {
        passwordInput.forceActiveFocus();
      });
    }
    onIsActiveChanged: {
      if (isActive)
        syncFromFlow();
      else
        reset();
    }
    onIsRegisteredChanged: {
      if (!isRegistered)
        console.warn("crux polkit agent is not registered; another agent may already be running");
    }
  }

  function syncFromFlow() {
    var flow = agent.flow;
    if (!flow)
      return;
    root.message = String(flow.message || "Authentication is needed");
    root.prompt = String(flow.inputPrompt || "Password");
    root.failed = !!flow.failed;
  }

  function reset() {
    submitted = false;
    failed = false;
    message = "";
    prompt = "";
    passwordInput.text = "";
  }

  function submit() {
    var flow = agent.flow;
    if (!flow || !flow.isResponseRequired)
      return;
    submitted = true;
    flow.submit(passwordInput.text);
    passwordInput.text = "";
  }

  function cancel() {
    var flow = agent.flow;
    passwordInput.text = "";
    if (flow)
      flow.cancelAuthenticationRequest();
  }

  Connections {
    target: agent.flow
    function onFailedChanged() {
      root.syncFromFlow();
      if (agent.flow && agent.flow.failed) {
        root.submitted = false;
        passwordInput.text = "";
        Qt.callLater(function () {
          passwordInput.forceActiveFocus();
        });
      }
    }
    function onAuthenticationSucceeded() {}
    function onAuthenticationRequestCancelled() {}
  }

  PanelWindow {
    id: panel
    visible: root.dialogVisible
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    color: "transparent"
    WlrLayershell.namespace: "crux-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: "#00000099"
    }

    Rectangle {
      id: card
      anchors.centerIn: parent
      width: 320
      height: column.implicitHeight + 24
      radius: 2
      color: "#1e1e2e"
      border.color: root.failed ? "#f38ba8" : "#45475a"
      border.width: 1

      Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: function (event) {
          if (event.key === Qt.Key_Escape) {
            root.cancel();
            event.accepted = true;
          }
        }

        ColumnLayout {
          id: column
          anchors.fill: parent
          anchors.margins: 12
          spacing: 8

          Text {
            text: "Authentication required"
            color: "#cdd6f4"
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: 13
            font.bold: true
            Layout.fillWidth: true
          }

          Text {
            text: root.message
            color: "#6c7086"
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          Text {
            visible: root.failed
            text: "Authentication failed — try again"
            color: "#f38ba8"
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: 11
            Layout.fillWidth: true
          }

          Item {
            Layout.fillWidth: true
            height: 30

            TextInput {
              id: passwordInput
              anchors.fill: parent
              anchors.margins: 6
              verticalAlignment: TextInput.AlignVCenter
              echoMode: TextInput.Password
              color: "#cdd6f4"
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: 13
              enabled: root.dialogVisible && !root.submitted
              onAccepted: root.submit()

              Rectangle {
                z: -1
                anchors.fill: parent
                anchors.margins: -6
                color: "#313244"
                radius: 2
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item {
              Layout.fillWidth: true
            }

            Text {
              text: "Cancel"
              color: "#6c7086"
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: 12
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cancel()
              }
            }

            Text {
              text: root.submitted ? "Checking…" : "OK"
              color: "#89b4fa"
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: 12
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !root.submitted
                onClicked: root.submit()
              }
            }
          }
        }
      }
    }
  }
}
