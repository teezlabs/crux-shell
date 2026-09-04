pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Blue-light filter via wlsunset: off -> on -> forced -> off. Owns the
// process so night light works whether or not the bar widget is present —
// see the crux skill's notes.md.
Singleton {
  id: root

  readonly property bool enabled: Settings.isLoaded ? Settings.data.nightLight.enabled : false
  readonly property bool forced: Settings.isLoaded ? Settings.data.nightLight.forced : false

  function init(): void {
    // Clear anything left over from a previous session before starting our
    // own; apply() runs from the kill's onExited.
    killStale.running = true;
  }

  // off -> on -> forced -> off
  function cycle(): void {
    if (!Settings.isLoaded)
      return;
    const nl = Settings.data.nightLight;
    if (!nl.enabled) {
      nl.enabled = true;
      nl.forced = false;
    } else if (!nl.forced) {
      nl.forced = true;
    } else {
      nl.enabled = false;
      nl.forced = false;
    }
  }

  function setEnabled(on): void {
    if (!Settings.isLoaded)
      return;
    Settings.data.nightLight.enabled = on;
    if (!on)
      Settings.data.nightLight.forced = false;
  }

  function buildCommand(): var {
    const nl = Settings.data.nightLight;
    const cmd = ["wlsunset", "-t", String(nl.nightTemp), "-T", String(nl.dayTemp)];
    if (nl.forced) {
      // Force full night temperature immediately: sunrise pinned almost a
      // full day away, sunset at midnight, near-instant transition.
      cmd.push("-S", "23:59", "-s", "00:00", "-d", "1");
    } else if (nl.useLocation && Weather.hasLocation) {
      cmd.push("-l", String(Weather.latitude), "-L", String(Weather.longitude));
    } else {
      cmd.push("-S", nl.manualSunrise, "-s", nl.manualSunset, "-d", "60");
    }
    return cmd;
  }

  function apply(): void {
    if (!Settings.isLoaded)
      return;
    runner.running = false;
    if (Settings.data.nightLight.enabled) {
      runner.command = root.buildCommand();
      runner.running = true;
    }
  }

  readonly property Process runner: Process {}

  readonly property Process killStale: Process {
    command: ["pkill", "-x", "wlsunset"]
    onExited: root.apply()
  }

  readonly property Connections settingsConn: Connections {
    target: Settings.isLoaded ? Settings.data.nightLight : null
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
    function onUseLocationChanged() {
      root.apply();
    }
  }

  // Geolocation resolves asynchronously. If useLocation was already on when
  // wlsunset first launched, that first apply() ran on the manual-schedule
  // fallback because Weather.hasLocation was still false — re-apply once it
  // actually arrives.
  readonly property Connections weatherConn: Connections {
    target: Weather
    function onHasLocationChanged() {
      if (Settings.isLoaded && Settings.data.nightLight.useLocation)
        root.apply();
    }
  }
}
