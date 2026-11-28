pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons

// Monitor layout for Settings › Display › Monitors (after lyne-dots). Apply tries the rules live with `hyprctl eval`
// and asks to keep them; Keep writes ~/.config/hypr/crux-monitors.lua, which hyprland.lua loads after its own
// monitor lines. Revert, or no answer within trialSeconds, reloads the config, which brings the saved layout back.
// A detached watcher reverts too, so a crash mid-trial can't leave a broken layout behind.
Singleton {
  id: root

  readonly property string filePath: Quickshell.env("HOME") + "/.config/hypr/crux-monitors.lua"
  readonly property string hyprConfig: Quickshell.env("HOME") + "/.config/hypr/hyprland.lua"
  readonly property string includeLine: "pcall(require, \"crux-monitors\")"
  readonly property string markerPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/crux-monitors-trial"
  readonly property int trialSeconds: 15

  // From `hyprctl monitors all -j`: { name, description, width, height, refresh, x, y, scale, transform, disabled, modes }
  property var monitors: []
  property string error: ""

  // hyprland.lua loads crux-monitors.lua; without it, Keep would have no lasting effect.
  readonly property bool includeInstalled: hyprFile.text().indexOf("crux-monitors") !== -1

  property bool trialActive: false
  property int trialRemaining: 0
  property var _pendingRules: []

  function refresh(): void {
    listProc.running = true;
  }

  // Logical size on the layout: pixels / scale, swapped for a quarter turn.
  function logicalSize(rule) {
    const w = rule.width / rule.scale;
    const h = rule.height / rule.scale;
    return rule.transform % 2 === 1 ? Qt.size(h, w) : Qt.size(w, h);
  }

  function _num(v) {
    return String(Math.round(v * 1000) / 1000);
  }

  function ruleToLua(rule) {
    if (rule.disabled)
      return "hl.monitor({ output = \"" + rule.name + "\", disabled = true })";
    return "hl.monitor({ output = \"" + rule.name + "\", disabled = false, mode = \"" + rule.width + "x" + rule.height + "@" + root._num(rule.refresh) + "\", position = \"" + Math.round(rule.x) + "x" + Math.round(rule.y) + "\", scale = " + root._num(rule.scale) + ", transform = " + rule.transform + " })";
  }

  // Refuses layouts that would leave no screen on.
  function problemWith(rules): string {
    if (rules.length === 0)
      return "No monitors";
    if (!rules.some(r => !r.disabled))
      return "At least one monitor has to stay on";
    return "";
  }

  function apply(rules): void {
    const problem = root.problemWith(rules);
    if (problem !== "") {
      root.error = problem;
      return;
    }
    root.error = "";
    root._pendingRules = rules;
    trialProc.command = ["hyprctl", "eval", rules.map(root.ruleToLua).join("\n")];
    trialProc.running = true;
  }

  function keep(): void {
    if (!root.trialActive)
      return;
    root._stopTrial();
    const lines = ["-- Monitors: written by crux (Settings › Display › Monitors). Loaded by hyprland.lua after its own monitor lines.", ""].concat(root._pendingRules.map(root.ruleToLua));
    // FileView.setText doesn't create a missing file, so write through a temp file and rename.
    writeProc.command = ["sh", "-c", 'printf "%s\\n" "$2" > "$1.tmp" && mv "$1.tmp" "$1"', "sh", root.filePath, lines.join("\n")];
    writeProc.running = true;
  }

  function revert(): void {
    if (!root.trialActive)
      return;
    root._stopTrial();
    Quickshell.execDetached(["hyprctl", "reload"]);
  }

  // Adds the include line after hyprland.lua's last hl.monitor() line, once.
  function installInclude(): void {
    installProc.running = true;
  }

  function _stopTrial(): void {
    root.trialActive = false;
    countdown.stop();
    Quickshell.execDetached(["rm", "-f", root.markerPath]);
  }

  Component.onCompleted: refresh()

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "monitoradded" || event.name === "monitorremoved" || event.name === "configreloaded" || event.name === "monitoraddedv2" || event.name === "monitorremovedv2")
        root.refresh();
    }
  }

  Process {
    id: listProc
    command: ["hyprctl", "monitors", "all", "-j"]
    stdout: StdioCollector {
      id: listOut
      waitForEnd: true
    }
    onExited: {
      try {
        const raw = JSON.parse(listOut.text);
        root.monitors = raw.filter(m => m.name && !m.name.startsWith("FALLBACK") && !m.name.startsWith("HEADLESS")).map(m => ({
              "name": m.name,
              "description": (m.make || "") + " " + (m.model || ""),
              "width": m.width,
              "height": m.height,
              "refresh": m.refreshRate,
              "x": m.x,
              "y": m.y,
              "scale": m.scale,
              "transform": m.transform,
              "disabled": !!m.disabled,
              "modes": m.availableModes || []
            }));
      } catch (e) {
        root.error = "Couldn't read the monitors";
      }
    }
  }

  Process {
    id: trialProc
    stdout: StdioCollector {
      id: trialOut
      waitForEnd: true
    }
    onExited: exitCode => {
      const out = trialOut.text.trim();
      if (exitCode !== 0 || (out !== "" && out !== "ok")) {
        root.error = out || "hyprctl eval failed";
        Quickshell.execDetached(["hyprctl", "reload"]);
        return;
      }
      root.trialActive = true;
      root.trialRemaining = root.trialSeconds;
      countdown.start();
      // Survives a crux crash: reloads the saved layout unless Keep/Revert removed the marker first.
      Quickshell.execDetached(["sh", "-c", "touch \"$1\"; sleep \"$2\"; if [ -e \"$1\" ]; then rm -f \"$1\"; hyprctl reload; fi", "sh", root.markerPath, String(root.trialSeconds + 3)]);
      root.refresh();
    }
  }

  Timer {
    id: countdown
    interval: 1000
    repeat: true
    onTriggered: {
      root.trialRemaining -= 1;
      if (root.trialRemaining <= 0)
        root.revert();
    }
  }

  FileView {
    id: hyprFile
    path: root.hyprConfig
    watchChanges: true
    onFileChanged: reload()
  }

  Process {
    id: writeProc
    onExited: exitCode => {
      if (exitCode === 0)
        Toast.show("Monitor layout saved", 2500);
      else
        root.error = "Couldn't write " + root.filePath;
    }
  }

  Process {
    id: installProc
    command: ["sh", "-c", "f=\"$1\"; line=\"$2\"; grep -q 'crux-monitors' \"$f\" && exit 0; cp \"$f\" \"$f.bak-crux\"; n=$(grep -n '^hl\\.monitor(' \"$f\" | tail -1 | cut -d: -f1); if [ -n \"$n\" ]; then sed -i \"${n}a $line\" \"$f\"; else printf '%s\\n' \"$line\" >> \"$f\"; fi", "sh", root.hyprConfig, root.includeLine]
    onExited: hyprFile.reload()
  }
}
