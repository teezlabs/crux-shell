import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.Commons

// PAM auth, ported from noctalia's LockContext without i18n, fprintd or auto-start.
Scope {
  id: root

  signal unlocked
  signal failed

  property string currentText: ""
  property bool waitingForPassword: false
  property bool unlockInProgress: false
  property bool showFailure: false
  property bool showInfo: false
  property string errorMessage: ""
  property string infoMessage: ""

  readonly property string pamConfigDirectory: "/etc/pam.d"
  property string pamConfig: "login"
  property bool pamReady: false

  Component.onCompleted: detectPamServiceProc.running = true

  // Probes for whichever PAM service file exists, as noctalia does; a hardcoded one fails on distros without it.
  Process {
    id: detectPamServiceProc
    command: ["sh", "-c", "
      if [ -f /etc/pam.d/login ]; then echo 'login'; exit 0; fi;
      if [ -f /etc/pam.d/system-auth ]; then echo 'system-auth'; exit 0; fi;
      if [ -f /etc/pam.d/common-auth ]; then echo 'common-auth'; exit 0; fi;
      echo 'login';
    "]
    stdout: StdioCollector {
      id: detectCollector
      waitForEnd: true
    }
    onExited: {
      var service = detectCollector.text.trim();
      root.pamConfig = service !== "" ? service : "login";
      root.pamReady = true;
    }
  }

  onShowInfoChanged: if (showInfo)
    showFailure = false
  onShowFailureChanged: if (showFailure)
    showInfo = false

  onCurrentTextChanged: {
    if (currentText !== "") {
      showInfo = false;
      showFailure = false;
      if (!waitingForPassword)
        pam.abort();
    }
  }

  function tryUnlock() {
    if (!pamReady)
      return;

    if (waitingForPassword) {
      pam.respond(currentText);
      unlockInProgress = true;
      waitingForPassword = false;
      showInfo = false;
      return;
    }

    pam.start();
  }

  PamContext {
    id: pam
    configDirectory: root.pamConfigDirectory
    config: root.pamConfig

    onPamMessage: {
      if (this.responseRequired) {
        if (root.currentText !== "") {
          this.respond(root.currentText);
          root.unlockInProgress = true;
        } else {
          root.waitingForPassword = true;
          root.infoMessage = "PASSWORD";
          root.showInfo = true;
        }
      } else if (messageIsError) {
        root.errorMessage = message;
        root.showFailure = true;
      } else {
        root.infoMessage = message;
        root.showInfo = true;
      }
    }

    onCompleted: result => {
      if (result === PamResult.Success) {
        root.unlocked();
      } else {
        root.currentText = "";
        root.errorMessage = "AUTHENTICATION FAILED";
        root.showFailure = true;
        root.failed();
      }
      root.unlockInProgress = false;
    }

    onError: {
      root.errorMessage = message || "AUTHENTICATION ERROR";
      root.showFailure = true;
      root.unlockInProgress = false;
      root.failed();
    }
  }
}
