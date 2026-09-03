pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Lean JSON-backed settings store. Grows as crux needs more, not before.
Singleton {
  id: root

  property bool isLoaded: false
  property bool directoriesCreated: false

  readonly property alias data: adapter // Settings.data.bar.position, etc.

  readonly property string shellName: "crux"
  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/" + shellName + "/"
  readonly property string settingsFile: configDir + "settings.json"

  signal settingsLoaded

  Component.onCompleted: {
    Quickshell.execDetached(["mkdir", "-p", configDir]);
    directoriesCreated = true;
    settingsFileView.adapter = adapter;
  }

  // Debounce writes so rapid changes (drag reorder, slider drag) don't hammer disk.
  Timer {
    id: saveTimer
    interval: 300
    onTriggered: root.saveImmediate()
  }

  function saveImmediate() {
    settingsFileView.writeAdapter();
  }

  FileView {
    id: settingsFileView
    path: root.directoriesCreated ? root.settingsFile : undefined
    printErrors: false
    watchChanges: true
    onAdapterUpdated: saveTimer.restart()

    onPathChanged: if (path !== undefined) reload()

    onLoaded: {
      if (!root.isLoaded) {
        root.isLoaded = true;
        root.settingsLoaded();
      }
    }
    onLoadFailed: function (error) {
      if (error.toString().includes("No such file") || error === 2) {
        // Fresh install: write current (default) adapter values as the file.
        writeAdapter();
      }
    }
  }

  JsonAdapter {
    id: adapter

    property JsonObject bar: JsonObject {
      property string position: "top" // "top" | "bottom" | "left" | "right"
      property list<string> monitors: [] // empty = show on all monitors
      property int widgetSpacing: 6
      property int contentPadding: 2
      property int thickness: 32 // cross-axis size (height when top/bottom, width when left/right)
      property int floatMargin: 6 // gap between the bar and the screen edge on every side
      property bool showBorder: true
      property real borderWidth: 1
      property bool autoHide: false // hide until the pointer touches the bar's screen edge
      property bool useSeparateOpacity: false // false = follow theme.barOpacity
      property real backgroundOpacity: 1.0 // used only when useSeparateOpacity is true

      // Detached floating modules when true, flush edge-to-edge strip when
      // false — opt-in toggle, see crux skill's notes.md.
      property bool floating: true
      // A real bar-strip background (distinct from useSeparateOpacity/
      // backgroundOpacity above, which only ever affected each module's
      // own individual chamfer fill) — off by default, keeping the current
      // "transparent bar, edge-glow line only" look until turned on.
      property bool showBackground: false
      property real barBackgroundOpacity: 0.85

      // Per-section widget lists: [{ "id": "Clock" }, ...]. Order = render
      // order. Defaults give a fresh install (no settings.json yet) an
      // actual populated bar instead of a bare strip — confirmed real bug:
      // these were empty arrays, so a genuinely new install (the AUR
      // package, a second machine, anyone without a hand-tuned settings
      // file already) booted to a bar with nothing on it at all.
      property JsonObject widgets: JsonObject {
        property list<var> left: [{
            "id": "ControlCenter"
          }, {
            "id": "Launcher"
          }, {
            "id": "Workspaces"
          }]
        property list<var> center: [{
            "id": "Clock"
          }]
        property list<var> right: [{
            "id": "Tray"
          }, {
            "id": "StatusGroup"
          }, {
            "id": "Settings"
          }, {
            "id": "PowerButton"
          }]
      }

      // Per-monitor overrides: [{ "name": "DP-1", "enabled": true, "position": "left", "widgets": {...} }]
      property list<var> screenOverrides: []
    }

    property JsonObject desktopWidgets: JsonObject {
      property bool enabled: true // weather + now-playing cards pinned to the desktop layer
      property bool weatherEnabled: true
      property bool mediaEnabled: true
      // Saved drag position, in screen-local pixels — -1 means "never moved
      // yet, use the default corner" (see DesktopWidgets.qml's
      // _marginLeft/_marginRight/_marginBottom bar-aware corner logic).
      property real weatherX: -1
      property real weatherY: -1
      property real mediaX: -1
      property real mediaY: -1
    }

    property JsonObject wallpaper: JsonObject {
      property string path: "" // current wallpaper, set live via `qs ipc call wallpaper set <path>`
      property string directory: (Quickshell.env("HOME") || "") + "/.config/wallpapers"
      // Per-monitor override: [{ "name": "DP-1", "path": "..." }] — a screen
      // not listed here just follows `path` above. See getWallpaperForScreen.
      property list<var> screenOverrides: []
      property bool autoTheme: true // regenerate theme colors (via matugen) whenever a wallpaper is picked

      // scheme-fidelity (not Material 3's default scheme-tonal-spot) — stays
      // close to the wallpaper's own saturation instead of tonal-spot's
      // deliberately muted/desaturated look.
      property string matugenScheme: "scheme-fidelity"
      // matugen --source-color-index: which of an image's dominant candidate
      // colors to theme from (0 = most dominant, up to 4).
      property int matugenColorIndex: 0

      // Auto-cycle — noctalia's Wallpaper "Automation" subtab: rotate to a
      // new wallpaper from `directory` on a timer, same set+retheme path a
      // manual pick uses (see shell.qml's wallpaperCycleTimer).
      property bool autoCycle: false
      property int autoCycleMinutes: 30
      property string autoCycleMode: "random" // "random" | "sequential"

      // Wallhaven search purity filter (its `purity` param — a 3-digit
      // sfw/sketchy/nsfw bitmask). NSFW results require a Wallhaven account
      // API key to actually come back; the toggle still works, it just
      // won't return anything without one.
      property bool wallhavenSfw: true
      property bool wallhavenSketchy: false
      property bool wallhavenNsfw: false
      // From wallhaven.cc/settings/account — required for NSFW purity and
      // for it to respect the account's own browsing settings.
      property string wallhavenApiKey: ""
      // Wallhaven's `atleast` (minimum resolution, e.g. "1920x1080") and
      // `ratios` params — both "" means no filter.
      property string wallhavenAtLeast: ""
      property string wallhavenRatio: ""

      // Shader-based switch transition — see Background.qml / crux skill's
      // notes.md. List, not single value: >1 checked picks randomly per switch.
      property list<string> transitionType: ["fade"]
      property int transitionDuration: 700 // ms
      property real transitionEdgeSmoothness: 0.05 // wipe/disc/stripes edge softness

      // System-wide app retheming (bin/theme-templates/*, applied via
      // matugen --config in Commons/Matugen.qml). Off by default — each is
      // a real write to a real app's config file.
      property JsonObject templates: JsonObject {
        property bool hyprland: false
        property bool kitty: false
        property bool gtk: false
        property bool qt: false
        property bool yazi: false
        property bool discord: false
        property bool pywalfox: false
        property bool btop: false
        property bool starship: false
        // Syncs /usr/share/sddm/themes/crux's background + colors to
        // whatever's actually live — see bin/crux-sync-greeter.
        property bool sddmGreeter: false
        // Sets gsettings color-scheme=prefer-dark — what GTK4/libadwaita
        // apps check for dark chrome, independent of the gtk.css @import.
        property bool gsettings: false
      }
    }

    property JsonObject general: JsonObject {
      property bool keepAwake: false // inhibit idle/screen-lock while true — Control Center toggle
      property string avatarImage: "" // "" = fall back to the Arch logo, ControlCenterWindow's header avatar
      // Applied live via `hyprctl keyword input:natural_scroll` on toggle,
      // and re-applied on boot (see shell.qml) since Hyprland doesn't
      // persist this itself — it's a runtime keyword, not read from
      // hyprland.lua.
      property bool reverseScroll: false
    }

    property JsonObject ui: JsonObject {
      // Bar clock format — a separate pair from lockScreen.clockFormat/
      // dateFormat below; the bar and lock screen are different surfaces
      // with their own space constraints, same reasoning that pair was
      // never shared with anything else either.
      property string clockFormat: "HH:mm"
      property string dateFormat: "ddd dd MMM"
      property string fontFamily: "Departure Mono"
      // Used only where code/commands are actually displayed (keybinds
      // viewer, hook command fields) — everything else stays on the one
      // shared fontFamily above. Not a general-purpose second font system;
      // crux has no per-role size scale to go with it, just the family.
      property string monoFontFamily: "Departure Mono"
      property real fontScale: 1.0 // multiplies every Tokens.*Size token
    }

    property JsonObject launcher: JsonObject {
      property bool fuzzyMatch: false // false = the original plain substring filter
      property int resultLimit: 30
      property bool sortByMostUsed: false // empty-query list only -- a real search always sorts by match quality
      property string appUsageCounts: "{}" // JSON-encoded {appId: launchCount}, bumped in LauncherWindow.qml's launch()
      // Typing this at the start of the query switches to "run this exact
      // shell command" mode instead of searching apps — LauncherWindow.qml
      // had a comment saying it was "apps-only today (no run/windows/calc
      // modes yet)"; this is that run mode. Empty string disables it.
      property string execPrefix: ">"
    }

    property JsonObject clipboard: JsonObject {
      property int historyLimit: 50 // entries shown/kept in the popup, sliced client-side from cliphist's own list
    }

    // Genuinely missing until now: Battery.qml (bar widget) and
    // BatteryPopupContent.qml both read Settings.data.battery.* — always a
    // TypeError on every boot, not something introduced by the popup
    // rewrite, just never wired into the schema before.
    property JsonObject battery: JsonObject {
      property int lowThreshold: 20 // % — statusColor/low-state cutoff
      property int criticalThreshold: 10 // % — statusColor/critical-state cutoff
      property bool showPowerProfile: true // PowerProfiles switcher row in the battery popup
    }

    property JsonObject audio: JsonObject {
      property real step: 0.05 // volume change per scroll notch / hardware key press
      // Lets scroll/hardware-key volume changes go past 100% (up to 150%)
      // instead of hard-capping at 1.0. Doesn't touch the popups' own
      // drag-slider ceiling (SegMeter.qml is a shared 0-100 component used
      // by Sound/Microphone/ControlCenter -- rescaling it is a bigger,
      // separate change), so overdriving past 100% still needs scroll or
      // the hardware keys, not the slider itself.
      property bool volumeOverdrive: false
      // MPRIS player.identity to prefer as "active" over the default
      // "Playing, else first" pick. "" = auto. Matched independently in
      // Media.qml, MediaPlayerWindow.qml, ControlCenterWindow.qml.
      property string preferredMediaPlayer: ""
    }

    property JsonObject hue: JsonObject {
      property string bridgeIp: ""
      property string username: ""
      property string selectedGroupId: ""
      property string selectedGroupName: ""
    }

    property JsonObject bluetooth: JsonObject {
      // Was hardcoded true in BluetoothModel.js's deviceLists() -- a
      // device that hasn't announced a real name yet (mid-pairing, some
      // odd peripherals) is invisible while this is on.
      property bool hideUnnamedDevices: true
    }

    property JsonObject osd: JsonObject {
      property bool enabled: true
      property string position: "bottom" // "top" | "center" | "bottom"
      property int durationMs: 1400 // spec §6.5: "Show 1.4s after the last input event"
      property real backgroundOpacity: 0.95 // was Tokens.panelOpacity, now user-adjustable
      property list<string> monitors: [] // empty = show on all monitors
    }

    // Which PowerMenuWindow actions are shown, and which require a second
    // tap within a short window before they actually run (arm-then-confirm,
    // simpler than a press-and-hold gesture but still catches fat-fingers
    // on anything destructive).
    property JsonObject sessionMenu: JsonObject {
      property list<string> enabledActions: ["Lock", "Suspend", "Logout", "Reboot", "Shutdown"]
      property list<string> confirmActions: ["Logout", "Reboot", "Shutdown"]
      property int confirmWindowMs: 2500 // how long a "confirm" action stays armed after the first tap
    }

    property JsonObject systemMonitor: JsonObject {
      property int refreshInterval: 2000 // ms between /proc/stat and /proc/meminfo reads
      // Per-metric warning/critical %, replacing one flat threshold for
      // every metric — CPU thermal headroom and disk fullness don't
      // usually warrant the same cutoff.
      property int cpuWarningThreshold: 80
      property int cpuCriticalThreshold: 90
      property int memWarningThreshold: 80
      property int memCriticalThreshold: 90
      property int diskWarningThreshold: 80
      property int diskCriticalThreshold: 90
      property int tempWarningThreshold: 80
      property int tempCriticalThreshold: 90
    }

    property JsonObject controlCenter: JsonObject {
      property bool showWeather: true
      property string tempUnit: "fahrenheit" // "fahrenheit" | "celsius" — passed straight to open-meteo
      property int statsRefreshInterval: 2000 // ms between CPU/MEM/TEMP/DISK reads
      property string screenshotCommand: "rishot" // run (via sh -c) by the CAPTURE action tile
      // Quick toggles shown in the top row, in order. Ids come from
      // Modules/Bar/Extras/CcToggleRegistry.qml.
      property list<string> toggles: ["Wifi", "Bluetooth", "Microphone", "NightLight"]
    }

    // Semantic color tokens ("m" prefix avoids QML reading "onPrimary" as
    // a signal handler name). Defaults match what every widget already
    // hardcoded — configurable, not a visual reset.
    property JsonObject theme: JsonObject {
      property string mPrimary: "#89b4fa" // accent
      property string mOnPrimary: "#1e1e2e"
      property string mSecondary: "#f38ba8" // warning/error accent
      property string mOnSecondary: "#1e1e2e"
      property string mSurface: "#1e1e2e" // popup/card background
      property string mOnSurface: "#cdd6f4" // primary text
      property string mSurfaceVariant: "#313244" // input fields, pills
      property string mOnSurfaceVariant: "#6c7086" // secondary/muted text
      property string mOutline: "#45475a" // borders, hover fill
      property string mError: "#f38ba8"
      property string mOnError: "#1e1e2e"

      property real barOpacity: 1.0 // 0..1, bar + popup background alpha

      // v2 spec's tonal-spot role set — additive alongside the m-prefixed
      // roles above (those stay live on widgets not yet migrated). Reference
      // hexes are matugen's default until a wallpaper regenerates them.
      property string surface: "#080B0E"
      property string surfaceContainerLow: "#0D1115"
      property string surfaceContainer: "#12171C"
      property string surfaceContainerHigh: "#1B2228"
      property string outline: "#333D45"
      property string outlineVariant: "#262E35"
      property string primary: "#7FD4E0"
      property string primaryContainer: "#1A4A52"
      property string primaryContainerText: "#B8ECF3"
      property string tertiary: "#D9BCC9"
      property string errorTone: "#F5A89F" // named errorTone, not error — JsonObject already has a built-in "error" signal
      property string surfaceText: "#DDE4E8"
      property string surfaceTextMuted: "#9AA5AC"

      // Name of the applied Assets/ColorSchemes preset, "" when the colors
      // came from a wallpaper via matugen instead.
      property string colorScheme: ""
    }

    property JsonObject brightness: JsonObject {
      property int step: 5 // % per scroll notch, Brightness.qml
      property bool enforceMinimum: true // never let brightnessctl hit 0%
    }

    property JsonObject nightLight: JsonObject {
      property bool enabled: false
      property bool forced: false // bypass the sunset/sunrise schedule, always-on
      property int nightTemp: 4000 // Kelvin
      property int dayTemp: 6500 // Kelvin, wlsunset's "no filter" value
      property string manualSunset: "19:00"
      property string manualSunrise: "06:00"
      // Real sunrise/sunset via wlsunset's own -l/-L sun-position math,
      // fed the same IP-geolocated lat/lon Commons/Weather.qml already
      // fetches for the Control Center weather card — falls back to the
      // manual schedule above if geolocation hasn't resolved yet.
      property bool useLocation: false
    }

    property JsonObject hooks: JsonObject {
      property bool enabled: true
      // Each a shell command string, run via Hooks.qml; "" = no-op.
      property string startup: ""
      property string wallpaperChange: ""
      property string colorGeneration: ""
      property string darkModeChange: ""
      property string screenLock: ""
      property string screenUnlock: ""
      property string session: ""
    }

    property JsonObject idle: JsonObject {
      property bool enabled: true
      property int screenOffTimeoutSec: 300
      property int lockTimeoutSec: 600
      property int suspendTimeoutSec: 900
      property int fadeDurationSec: 10
      // "" falls back to Idle.qml's own built-in default for that stage;
      // resumeSuspendCommand has no built-in fallback (see Idle.qml).
      property string screenOffCommand: ""
      property string resumeScreenOffCommand: ""
      property string lockCommand: ""
      property string suspendCommand: ""
      property string resumeSuspendCommand: ""
      property string customCommands: "[]" // JSON-encoded array of extra {timeoutSec, command} entries
    }

    property JsonObject lockScreen: JsonObject {
      property string clockFormat: "HH:mm"
      property string dateFormat: "dddd d MMMM yyyy"
      property bool useCustomWallpaper: false
      property string customWallpaperPath: ""
      property real blurAmount: 1.0
      property real dimAmount: 0.35
      property bool showNetwork: true
      property bool showBattery: true
      property bool showVolume: true
      property bool showNotifications: true
      property bool showMediaControls: true // read-only now-playing line, not interactive -- no new tappable surface on the lock screen
      property int gracePeriodSec: 0 // 0 = off, no delay before the lock actually engages
      property int maxFailedAttempts: 0 // 0 = unlimited
      property int lockoutDurationSec: 30
      property list<string> monitors: [] // empty = show on all monitors
    }

    property JsonObject notifications: JsonObject {
      property bool enabled: true
      property bool doNotDisturb: false
      property int maxVisible: 5
      property string position: "top_right" // "top_left" | "top_right" | "bottom_left" | "bottom_right"
      property int historyLimit: 50
      property int lowUrgencyDurationSec: 4
      property int normalUrgencyDurationSec: 6
      property int criticalUrgencyDurationSec: 0 // 0 = never auto-expire
      property bool respectAppExpireTimeout: true
      property real backgroundOpacity: 0.94
      property list<string> monitors: [] // empty = show on all monitors
    }

    property JsonObject keyboard: JsonObject {
      property string deviceName: "" // "" = follow Hyprland's default active keyboard
    }

    property JsonObject lockKeys: JsonObject {
      property bool showCapsLock: true
      property bool showNumLock: true
      property bool showScrollLock: true
      property bool hideWhenOff: false // hide each indicator entirely instead of dimming it when its lock is off
    }

    // Marketplace sources for Commons/Plugins.qml -- each a git repo with
    // a registry.json at its root listing {id, label, description, ...}
    // per plugin. Local-folder plugins (no source) still work as before.
    property JsonObject plugins: JsonObject {
      property list<var> sources: [] // [{ "url": "...", "name": "...", "enabled": true }]
    }
  }

  // -----------------------------------------------------
  // Per-screen resolution (falls back to the global bar.* value)

  function _findScreenOverride(screenName) {
    var overrides = data.bar.screenOverrides;
    if (!screenName || !overrides || overrides.length === undefined) {
      return null;
    }
    for (var i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        return overrides[i];
      }
    }
    return null;
  }

  function getBarPositionForScreen(screenName) {
    var override = _findScreenOverride(screenName);
    if (override && override.enabled !== false && override.position !== undefined) {
      return override.position;
    }
    return data.bar.position || "top";
  }

  // True if this screen has its own enabled position override (as opposed
  // to just following data.bar.position globally) — for the settings
  // panel's per-monitor override UI to know whether to show it as "custom".
  function hasPositionOverride(screenName) {
    var override = _findScreenOverride(screenName);
    return !!(override && override.enabled !== false && override.position !== undefined);
  }

  function getBarWidgetsForScreen(screenName) {
    var override = _findScreenOverride(screenName);
    if (override && override.enabled !== false && override.widgets !== undefined) {
      return override.widgets;
    }
    return data.bar.widgets;
  }

  // Moves a widget within one section, on whichever list is actually
  // effective for this screen — same resolution rule getBarWidgetsForScreen() uses.
  function reorderBarWidget(screenName, section, fromIndex, toIndex) {
    if (fromIndex === toIndex)
      return;

    var override = _findScreenOverride(screenName);
    var usesOverride = !!(override && override.enabled !== false && override.widgets !== undefined);
    var widgets = JSON.parse(JSON.stringify(usesOverride ? override.widgets : data.bar.widgets));
    var list = widgets[section];
    // toIndex === list.length is valid — "move to the end".
    if (!list || fromIndex < 0 || fromIndex >= list.length || toIndex < 0 || toIndex > list.length)
      return;

    var moved = list.splice(fromIndex, 1)[0];
    list.splice(toIndex, 0, moved);

    if (usesOverride) {
      setScreenOverride(screenName, "widgets", widgets);
    } else {
      // bar.widgets is a JsonObject, not a plain list<var> — reassigning the
      // whole object (data.bar.widgets = widgets) silently doesn't persist.
      // Assign directly to the affected list<var> sub-property instead,
      // same as how screenOverrides (itself a list<var>) is written above.
      data.bar.widgets[section] = list;
    }
  }

  // Moves the widget at fromIndex in fromSection to toIndex in toSection —
  // the cross-section counterpart to reorderBarWidget above. Same
  // effective-list resolution rule.
  function moveBarWidget(screenName, fromSection, fromIndex, toSection, toIndex) {
    if (fromSection === toSection) {
      reorderBarWidget(screenName, fromSection, fromIndex, toIndex);
      return;
    }

    var override = _findScreenOverride(screenName);
    var usesOverride = !!(override && override.enabled !== false && override.widgets !== undefined);
    var widgets = JSON.parse(JSON.stringify(usesOverride ? override.widgets : data.bar.widgets));
    var fromList = widgets[fromSection];
    var toList = widgets[toSection];
    if (!fromList || !toList || fromIndex < 0 || fromIndex >= fromList.length)
      return;

    var moved = fromList.splice(fromIndex, 1)[0];
    var insertAt = Math.max(0, Math.min(toIndex, toList.length));
    toList.splice(insertAt, 0, moved);
    widgets[fromSection] = fromList;
    widgets[toSection] = toList;

    if (usesOverride) {
      setScreenOverride(screenName, "widgets", widgets);
    } else {
      data.bar.widgets[fromSection] = fromList;
      data.bar.widgets[toSection] = toList;
    }
  }

  // Appends a widget id to the end of one section — for the settings
  // panel's "add widget" control. Same effective-list resolution rule.
  // Control Center quick toggles. A plain ordered list — no per-screen
  // overrides, unlike the bar's widgets.
  //
  // Reassigning the whole list<string> property is what persists here;
  // mutating the array in place does not (same trap reorderBarWidget hit).
  // Unknown ids are the loader's problem to refuse (CcToggleRegistry lives
  // in Modules, and Commons shouldn't reach up into it).
  function addCcToggle(id) {
    const list = data.controlCenter.toggles.slice();
    if (list.indexOf(id) !== -1)
      return;
    list.push(id);
    data.controlCenter.toggles = list;
  }

  function removeCcToggle(index) {
    const list = data.controlCenter.toggles.slice();
    if (index < 0 || index >= list.length)
      return;
    list.splice(index, 1);
    data.controlCenter.toggles = list;
  }

  function moveCcToggle(index, delta) {
    const list = data.controlCenter.toggles.slice();
    const to = index + delta;
    if (index < 0 || index >= list.length || to < 0 || to >= list.length)
      return;
    const item = list.splice(index, 1)[0];
    list.splice(to, 0, item);
    data.controlCenter.toggles = list;
  }

  function addBarWidget(screenName, section, widgetId) {
    var override = _findScreenOverride(screenName);
    var usesOverride = !!(override && override.enabled !== false && override.widgets !== undefined);
    var widgets = JSON.parse(JSON.stringify(usesOverride ? override.widgets : data.bar.widgets));
    var list = widgets[section];
    if (!list)
      return;
    list.push({
      "id": widgetId
    });

    if (usesOverride) {
      setScreenOverride(screenName, "widgets", widgets);
    } else {
      data.bar.widgets[section] = list;
    }
  }

  // Removes the widget at index from one section — for the settings
  // panel's per-row remove button.
  function removeBarWidget(screenName, section, index) {
    var override = _findScreenOverride(screenName);
    var usesOverride = !!(override && override.enabled !== false && override.widgets !== undefined);
    var widgets = JSON.parse(JSON.stringify(usesOverride ? override.widgets : data.bar.widgets));
    var list = widgets[section];
    if (!list || index < 0 || index >= list.length)
      return;
    list.splice(index, 1);

    if (usesOverride) {
      setScreenOverride(screenName, "widgets", widgets);
    } else {
      data.bar.widgets[section] = list;
    }
  }

  // Sets one property on a screen's override entry, creating the entry if needed.
  function setScreenOverride(screenName, property, value) {
    if (!screenName)
      return;

    var overrides = JSON.parse(JSON.stringify(data.bar.screenOverrides || []));
    if (overrides.length === undefined) {
      overrides = [];
    }

    var index = -1;
    for (var i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        index = i;
        break;
      }
    }

    if (index === -1) {
      var newEntry = {
        "name": screenName
      };
      newEntry[property] = value;
      overrides.push(newEntry);
    } else {
      overrides[index][property] = value;
    }
    data.bar.screenOverrides = overrides;
  }

  // Falls back to the global wallpaper.path when screenName has no override.
  function getWallpaperForScreen(screenName) {
    var overrides = data.wallpaper.screenOverrides || [];
    for (var i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName && overrides[i].path)
        return overrides[i].path;
    }
    return data.wallpaper.path;
  }

  // screenName === "" (or falsy) sets the global wallpaper and clears every
  // screen's override, so "apply to all monitors" doesn't leave stale
  // per-monitor overrides shadowing it.
  function setWallpaperForScreen(screenName, path) {
    if (!screenName) {
      data.wallpaper.path = path;
      data.wallpaper.screenOverrides = [];
      return;
    }

    var overrides = JSON.parse(JSON.stringify(data.wallpaper.screenOverrides || []));
    var index = -1;
    for (var i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        index = i;
        break;
      }
    }
    if (index === -1)
      overrides.push({
        "name": screenName,
        "path": path
      });
    else
      overrides[index].path = path;
    data.wallpaper.screenOverrides = overrides;
  }
}
