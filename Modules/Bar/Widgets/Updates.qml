import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras

// System package update count. Detection follows noctalia's "update-count"
// plugin: yay first (official repos via `checkupdates`, a read-only sync
// that doesn't touch the live pacman db/lock, plus AUR via `yay -Qua`, a
// local query), falling back to pacman-only when yay isn't installed. A
// total only — no repo/AUR split, no package list.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  property int updateCount: -1 // -1 = not checked yet
  property bool checking: false
  property bool hasYay: false

  readonly property var cfg: Settings.data.updates
  readonly property bool hasUpdates: root.updateCount > 0
  readonly property bool shouldHide: root.cfg.hideOnZero && root.updateCount === 0

  readonly property string _ipcTarget: "updates_" + (root.screen ? root.screen.name : "0")

  // One instance per monitor, so a post-update recheck aimed at a single
  // screen's IPC target left every other bar showing a stale count until
  // its own interval came round. They all watch this one file instead.
  readonly property string _stampDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/crux"
  readonly property string _stampFile: root._stampDir + "/update-count-stamp"

  property real _nextCheckAt: Date.now() + root.cfg.intervalMinutes * 60 * 1000
  property int _countdownTick: 0
  readonly property int secondsToNextCheck: Math.max(0, Math.round((root._nextCheckAt - Date.now()) / 1000))
  readonly property string countdownLabel: {
    root._countdownTick;
    const s = root.secondsToNextCheck;
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  function check(): void {
    if (root.checking)
      return;
    root.checking = true;
    root._nextCheckAt = Date.now() + root.cfg.intervalMinutes * 60 * 1000;
    if (root.cfg.customCountCmd) {
      countProc.command = ["sh", "-c", root.cfg.customCountCmd];
      countProc.running = true;
    } else {
      detectProc.running = true;
    }
  }

  function runUpdate(): void {
    const updateCmd = root.cfg.customUpdateCmd || (root.hasYay ? "yay -Syu" : "sudo pacman -Syu");
    const combined = updateCmd + " ; mkdir -p " + root._stampDir + " && date +%s%N > " + root._stampFile;
    const term = root.cfg.terminalCommand.trim();
    const fullCmd = term.indexOf("{}") !== -1 ? term.replace("{}", combined) : term + " sh -c \"" + combined.replace(/"/g, "\\\"") + "\"";
    Quickshell.execDetached(["sh", "-c", fullCmd]);
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root._countdownTick++
  }

  Timer {
    interval: root.cfg.intervalMinutes * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.check()
  }

  FileView {
    path: root._stampFile
    printErrors: false
    watchChanges: true
    // Also fires on the initial load, which is harmless — check() guards
    // against overlapping runs and the interval timer starts one anyway.
    onFileChanged: {
      reload();
      root.check();
    }
  }

  IpcHandler {
    target: root._ipcTarget
    function check(): void {
      root.check();
    }
  }

  Process {
    id: detectProc
    command: ["sh", "-c", "command -v yay >/dev/null && echo yay || echo pacman"]
    stdout: StdioCollector {
      id: detectCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      root.hasYay = detectCollector.text.trim() === "yay";
      countProc.command = root.hasYay ? ["sh", "-c", "(checkupdates 2>/dev/null; yay -Qua 2>/dev/null) | wc -l"] : ["sh", "-c", "checkupdates 2>/dev/null | wc -l"];
      countProc.running = true;
    }
  }

  Process {
    id: countProc
    stdout: StdioCollector {
      id: countCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      const n = parseInt(countCollector.text.trim());
      root.updateCount = isNaN(n) ? 0 : n;
      root.checking = false;
    }
  }

  // BarSection sizes each slot off implicitWidth/implicitHeight, not
  // `visible` — QML's visible hides rendering without collapsing layout
  // size, so these must go to 0 too or the bar keeps a dead gap.
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
        valueColor: root.hasUpdates ? Color.tertiary : Color.surfaceTextMuted
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
          color: root.hasUpdates ? Color.tertiary : Color.surfaceTextMuted
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
        Text {
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "UPD"
          color: Color.labelText
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
        msg += " · next check in " + root.countdownLabel;
        msg += "\nRight-click: settings";
        TooltipService.show(root, msg);
      } else {
        TooltipService.hide();
      }
    }
  }

  // Left click runs the real update in a terminal when there's something to
  // install, otherwise just re-checks.
  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: root.hasUpdates ? root.runUpdate() : root.check()
  }
  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: {
      TooltipService.hideImmediately();
      Popups.openTab("settings", root.screen, "updates");
    }
  }
}
