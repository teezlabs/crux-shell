import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// greetd login flow: pick a user and session, answer the PAM prompts, launch the session.
Scope {
  id: root

  // Outside greetd (a normal session) the UI runs as a preview; nothing is ever sent to PAM.
  readonly property bool preview: !Greetd.available

  property var users: []
  property int userIndex: 0
  readonly property var user: users.length > 0 ? users[userIndex] : null

  property var sessions: []
  property int sessionIndex: 0
  readonly property var session: sessions.length > 0 ? sessions[sessionIndex] : null

  property string currentText: ""
  property string prompt: "PASSWORD"
  property bool echoResponse: false
  property bool busy: false
  property string errorMessage: ""
  property string infoMessage: ""
  property int failedAttempts: 0

  // An Enter before greetd asked anything: the first secret prompt gets the typed text.
  property bool _answerFirstPrompt: false
  property bool _awaitingResponse: false

  function cycleUser(step) {
    if (busy || users.length < 2)
      return;
    userIndex = (userIndex + step + users.length) % users.length;
    _reset();
  }

  function cycleSession(step) {
    if (busy || sessions.length < 2)
      return;
    sessionIndex = (sessionIndex + step + sessions.length) % sessions.length;
  }

  function submit() {
    if (busy || !user || !session)
      return;
    errorMessage = "";
    infoMessage = "";
    if (preview) {
      currentText = "";
      errorMessage = "PREVIEW — NOT CONNECTED TO GREETD";
      return;
    }
    busy = true;
    if (_awaitingResponse) {
      _awaitingResponse = false;
      Greetd.respond(currentText);
      return;
    }
    _answerFirstPrompt = true;
    Greetd.createSession(user.name);
  }

  function _reset() {
    if (!preview && Greetd.state !== GreetdState.Inactive)
      Greetd.cancelSession();
    currentText = "";
    prompt = "PASSWORD";
    echoResponse = false;
    busy = false;
    errorMessage = "";
    infoMessage = "";
    _answerFirstPrompt = false;
    _awaitingResponse = false;
  }

  Connections {
    target: Greetd
    enabled: !root.preview

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (!responseRequired) {
        if (error)
          root.errorMessage = message.toUpperCase();
        else
          root.infoMessage = message.toUpperCase();
        return;
      }
      if (root._answerFirstPrompt && !echoResponse) {
        root._answerFirstPrompt = false;
        Greetd.respond(root.currentText);
        return;
      }
      // A further prompt (a second factor, a username): hand the field back to the user.
      root._answerFirstPrompt = false;
      root._awaitingResponse = true;
      root.prompt = message ? message.replace(/:\s*$/, "").toUpperCase() : "RESPONSE";
      root.echoResponse = echoResponse;
      root.currentText = "";
      root.busy = false;
    }

    function onAuthFailure(message) {
      root.failedAttempts += 1;
      root._reset();
      root.errorMessage = message ? message.toUpperCase() : "AUTHENTICATION FAILED";
    }

    function onReadyToLaunch() {
      root.infoMessage = "STARTING " + root.session.name.toUpperCase();
      Greetd.launch(root.session.command, root.session.environment, true);
    }

    function onError(error) {
      root._reset();
      root.errorMessage = error ? error.toUpperCase() : "GREETD ERROR";
    }
  }

  // Real login accounts: uid 1000-59999 with a usable shell.
  Process {
    running: true
    command: ["getent", "passwd"]
    stdout: StdioCollector {
      id: passwdOut
      waitForEnd: true
    }
    onExited: {
      var list = [];
      var lines = passwdOut.text.split("\n");
      for (var i = 0; i < lines.length; i++) {
        var f = lines[i].split(":");
        if (f.length < 7)
          continue;
        var uid = parseInt(f[2]);
        if (uid < 1000 || uid >= 60000 || /(nologin|false)$/.test(f[6]))
          continue;
        var gecos = f[4].split(",")[0];
        list.push({
          "name": f[0],
          "label": gecos || f[0]
        });
      }
      root.users = list;
    }
  }

  // A dry-run login for testing greetd: the only session is this shell command instead of a desktop.
  readonly property string testSession: Quickshell.env("CRUX_GREETER_TEST_SESSION") || ""
  Component.onCompleted: if (testSession)
    sessions = [
      {
        "name": "Test",
        "command": [testSession],
        "environment": []
      }
    ]

  // Wayland sessions whose TryExec (or first Exec word) is installed; start-hyprland first, as SDDM had it.
  Process {
    running: root.testSession === ""
    command: ["sh", "-c", "for f in /usr/share/wayland-sessions/*.desktop; do " + "n=$(sed -n 's/^Name=//p' \"$f\" | head -1); " + "e=$(sed -n 's/^Exec=//p' \"$f\" | head -1); " + "t=$(sed -n 's/^TryExec=//p' \"$f\" | head -1); " + "d=$(sed -n 's/^DesktopNames=//p' \"$f\" | head -1); " + "[ -n \"$e\" ] || continue; " + "command -v \"${t:-${e%% *}}\" >/dev/null 2>&1 || continue; " + "printf '%s\\t%s\\t%s\\n' \"$n\" \"$e\" \"$d\"; done"]
    stdout: StdioCollector {
      id: sessionsOut
      waitForEnd: true
    }
    onExited: {
      var list = [];
      var lines = sessionsOut.text.split("\n");
      for (var i = 0; i < lines.length; i++) {
        var f = lines[i].split("\t");
        if (f.length < 3 || !f[1])
          continue;
        var env = ["XDG_SESSION_TYPE=wayland"];
        if (f[2])
          env.push("XDG_CURRENT_DESKTOP=" + f[2].replace(/;$/, "").replace(/;/g, ":"));
        list.push({
          "name": f[0] || f[1],
          // greetd joins the argv with spaces and runs it through sh -c, so the Exec line goes over whole.
          "command": [f[1].replace(/ %[a-zA-Z]/g, "").trim()],
          "environment": env
        });
      }
      list.sort(function (a, b) {
        return (b.command[0].indexOf("start-hyprland") === 0) - (a.command[0].indexOf("start-hyprland") === 0);
      });
      root.sessions = list;
    }
  }
}
