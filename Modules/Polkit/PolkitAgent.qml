import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs.Commons

// Polkit authentication agent. This machine has none running (referenced
// "hyprpolkitagent" systemd unit doesn't exist — pkexec fails silently
// with no agent to prompt), so this fills a genuine gap, not a duplicate.
// API confirmed from Omarchy's real PolkitAgent.qml; UI rebuilt plain.
// Real PAM auth flow — never trigger it programmatically for testing; see
// crux skill notes on faillock lockout risk.
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
      radius: Style.radiusXXS
      color: Color.mSurface
      border.color: root.failed ? Color.mError : Color.mOutline
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
            color: Color.mOnSurface
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: 13
            font.bold: true
            Layout.fillWidth: true
          }

          Text {
            text: root.message
            color: Color.mOnSurfaceVariant
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          Text {
            visible: root.failed
            text: "Authentication failed — try again"
            color: Color.mError
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
              color: Color.mOnSurface
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: 13
              enabled: root.dialogVisible && !root.submitted
              onAccepted: root.submit()

              Rectangle {
                z: -1
                anchors.fill: parent
                anchors.margins: -6
                color: Color.mSurfaceVariant
                radius: Style.radiusXXS
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
              color: Color.mOnSurfaceVariant
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
              color: Color.mPrimary
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
