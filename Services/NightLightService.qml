pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// wlsunset owner, off -> on -> forced, so night light works without the bar widget.
Singleton {
  id: root

  readonly property bool enabled: Settings.isLoaded ? Settings.data.nightLight.enabled : false
  readonly property bool forced: Settings.isLoaded ? Settings.data.nightLight.forced : false

  function init(): void {
    // Kill a leftover wlsunset first; apply() runs from the kill's onExited.
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
      // Forced: full night temperature now, with sunrise pinned almost a day away.
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

  // Re-apply once geolocation arrives, in case the first launch fell back to the manual schedule.
  readonly property Connections weatherConn: Connections {
    target: Weather
    function onHasLocationChanged() {
      if (Settings.isLoaded && Settings.data.nightLight.useLocation)
        root.apply();
    }
  }
}
