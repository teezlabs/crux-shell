import QtQuick
import Quickshell
import Quickshell.Io
import qs.Modules.Bar.Extras
import qs.Commons

// Blue-light filter toggle, backed by `wlsunset` — the same tool
// noctalia's Services/Location/NightLightService.qml drives (its
// auto-schedule mode uses geolocation via a LocationService crux doesn't
// have yet; only the manual sunset/sunrise schedule that service also
// supports was ported — see Settings.data.nightLight and the Display >
// Night Light settings tab). Click cycles off -> on -> forced -> off,
// same three-state UX as noctalia's own bar icon.
//
// This widget instantiates once per monitor the bar's on, but wlsunset
// itself must run exactly once shell-wide — every instance reflects
// Settings.data.nightLight.enabled for its own icon, but only the instance
// on Quickshell.screens[0] actually manages the wlsunset process, same
// "gate to one instance" pattern crux already uses for per-screen
// IpcHandlers (see SoundMenuWindow.qml and friends).
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property bool active: Settings.data.nightLight.enabled
  readonly property bool forced: Settings.data.nightLight.forced

  // Deliberately NOT a live computed binding (`readonly property bool: ...
  // Quickshell.screens[0]...`) — confirmed via direct debug logging that a
  // binding reading through `Quickshell.screens[0]` (array-index access)
  // does not reliably re-evaluate when `screen` arrives: same class of bug
  // as the documented Grid/`itemAt()` dependency-tracking gotcha ("reads
  // mediated through itemAt() aren't tracked reliably... reading your own
  // property directly is always picked up"). Also confirmed comparing by
  // object identity (`root.screen === Quickshell.screens[0]`) doesn't work
  // here either — two real monitors, both instances printed `primary=false`
  // against Quickshell.screens[0], even though the two are supposed to be
  // the same QuickshellScreenInfo. This same `===` pattern is used
  // elsewhere in crux (SoundMenuWindow.qml and friends' per-screen
  // IpcHandler gates) — worth re-checking those on real multi-monitor
  // hardware, since they may have the same latent bug.
  //
  // Fix: compute it imperatively into a plain stored property at the exact
  // points that matter (screen arriving, completion), instead of trusting
  // either binding form to invalidate itself.
  property bool _isPrimaryInstance: false
  property bool _initDone: false

  function _computeIsPrimary() {
    return !!root.screen && Quickshell.screens.length > 0 && root.screen.name === Quickshell.screens[0].name;
  }

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  function buildCommand() {
    var cmd = ["wlsunset", "-t", String(Settings.data.nightLight.nightTemp), "-T", String(Settings.data.nightLight.dayTemp)];
    if (Settings.data.nightLight.forced) {
      // Force full night temperature immediately: sunrise pinned almost a
      // full day away, sunset at midnight, near-instant transition.
      cmd.push("-S", "23:59", "-s", "00:00", "-d", "1");
    } else {
      cmd.push("-S", Settings.data.nightLight.manualSunrise, "-s", Settings.data.nightLight.manualSunset, "-d", "60");
    }
    return cmd;
  }

  function apply() {
    if (!root._isPrimaryInstance)
      return;
    runner.running = false;
    if (Settings.data.nightLight.enabled) {
      runner.command = root.buildCommand();
      runner.running = true;
    }
  }

  Process {
    id: runner
  }

  Process {
    id: killStale
    command: ["pkill", "-x", "wlsunset"]
    onExited: {
      root.apply();
    }
  }

  // BarWidgetLoader assigns `screen` in its Loader.onLoaded, which runs
  // AFTER this item's own Component.onCompleted — so `screen` (and thus
  // `_isPrimaryInstance`) isn't reliably set yet at completion time.
  // React to `screen` actually arriving instead of gating everything on
  // Component.onCompleted alone (confirmed real bug: wlsunset never
  // launched on startup even with nightLight.enabled true, since
  // _isPrimaryInstance always read false at onCompleted).
  function _maybeInit() {
    root._isPrimaryInstance = root._computeIsPrimary();
    if (root._isPrimaryInstance && !root._initDone) {
      root._initDone = true;
      killStale.running = true;
    }
  }

  onScreenChanged: root._maybeInit()

  Component.onCompleted: {
    root._maybeInit();
  }

  Connections {
    target: Settings.data.nightLight
    enabled: root._isPrimaryInstance
    function onEnabledChanged() {
      root.apply();
    }
    function onForcedChanged() {
      root.apply();
    }
    function onNightTempChanged() {
      root.apply();
    }
    function onDayTempChanged() {
      root.apply();
    }
    function onManualSunriseChanged() {
      root.apply();
    }
    function onManualSunsetChanged() {
      root.apply();
    }
  }

  BarIconButton {
    id: btn
    attention: root.forced
    onTapped: {
      // off -> on -> forced -> off
      if (!Settings.data.nightLight.enabled) {
        Settings.data.nightLight.enabled = true;
        Settings.data.nightLight.forced = false;
      } else if (!Settings.data.nightLight.forced) {
        Settings.data.nightLight.forced = true;
      } else {
        Settings.data.nightLight.enabled = false;
        Settings.data.nightLight.forced = false;
      }
    }

    // Crescent-moon glyph (circle minus an offset circle) — outline when
    // off, filled primary when on, filled tertiary when forced. No
    // font/emoji glyph dependency.
    Canvas {
      id: moonCanvas
      anchors.centerIn: parent
      width: 16
      height: 16
      readonly property color drawColor: root.forced ? Color.tertiary : (root.active ? Color.primary : Color.surfaceTextMuted)
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = drawColor;
        ctx.strokeStyle = drawColor;
        ctx.lineWidth = 1.4;

        var cx = width / 2;
        var cy = height / 2;
        var r = 6;

        if (root.active) {
          ctx.beginPath();
          ctx.arc(cx, cy, r, 0, Math.PI * 2);
          ctx.fill();
          ctx.globalCompositeOperation = "destination-out";
          ctx.beginPath();
          ctx.arc(cx + 3, cy - 2, r - 1.5, 0, Math.PI * 2);
          ctx.fill();
          ctx.globalCompositeOperation = "source-over";
        } else {
          ctx.beginPath();
          ctx.arc(cx, cy, r - 1, 0, Math.PI * 2);
          ctx.stroke();
        }
      }
    }
  }
}
