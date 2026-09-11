pragma Singleton

import QtQml
import QtQuick
import Quickshell
import qs.Commons

// Philips Hue bridge control, ported from noctalia-shell's HueService.qml.
// No local discovery-mesh/zigbee talk — everything goes through the
// bridge's own local HTTP API (v1, the same one noctalia targets), reached
// directly over the LAN once paired.
Singleton {
  id: root

  readonly property string bridgeIp: Settings.data.hue.bridgeIp
  readonly property string username: Settings.data.hue.username
  readonly property bool paired: bridgeIp !== "" && username !== ""

  property bool discovering: false
  property string discoveryError: ""

  property bool pairing: false
  property string pairingError: ""
  property int pairingSecondsLeft: 0

  // Raw group data from the bridge - only reassigned when the set of groups changes (fetch/refresh),
  // never on brightness/on-off updates, so it can't feed a reactive loop through selectedGroup.
  property var groupsData: [] // [{ groupId, name, on, brightness01 }]

  // Persistent Group objects (stable identity) mirroring groupsData, mutated in place
  property var groups: []
  property bool fetchingGroups: false
  property string groupsError: ""

  function getGroup(groupId) {
    for (var i = 0; i < root.groups.length; i++) {
      if (root.groups[i].groupId === groupId)
        return root.groups[i];
    }
    return null;
  }

  readonly property QtObject selectedGroup: root.getGroup(Settings.data.hue.selectedGroupId)

  function selectGroup(groupId, groupName) {
    Settings.data.hue.selectedGroupId = groupId;
    Settings.data.hue.selectedGroupName = groupName;
  }

  function forget() {
    pairingTimer.stop();
    Settings.data.hue.bridgeIp = "";
    Settings.data.hue.username = "";
    Settings.data.hue.selectedGroupId = "";
    Settings.data.hue.selectedGroupName = "";
    root.groupsData = [];
  }

  // --------------------------------
  // Bridge discovery (Hue's public N-UPnP discovery endpoint - no auth required)
  function discoverBridge() {
    if (root.discovering)
      return;

    root.discovering = true;
    root.discoveryError = "";

    const request = new XMLHttpRequest();
    request.onreadystatechange = function () {
      if (request.readyState !== XMLHttpRequest.DONE)
        return;

      root.discovering = false;

      if (request.status !== 200) {
        root.discoveryError = "Discovery request failed.";
        console.warn("[Hue] Discovery request failed with status:", request.status);
        return;
      }

      try {
        const results = JSON.parse(request.responseText);
        if (Array.isArray(results) && results.length > 0 && results[0].internalipaddress) {
          Settings.data.hue.bridgeIp = results[0].internalipaddress;
          console.log("[Hue] Discovered bridge at:", results[0].internalipaddress);
        } else {
          root.discoveryError = "No bridge found on the network.";
        }
      } catch (e) {
        root.discoveryError = "Discovery request failed.";
        console.warn("[Hue] Failed to parse discovery response:", e);
      }
    };

    request.onerror = function () {
      root.discovering = false;
      root.discoveryError = "Discovery request failed.";
    };

    request.open("GET", "https://discovery.meethue.com/");
    request.send();
  }

  // --------------------------------
  // Pairing: repeatedly POST /api until the user presses the bridge's physical link button
  Timer {
    id: pairingTimer
    interval: 1000
    repeat: true
    onTriggered: {
      root.pairingSecondsLeft--;
      if (root.pairingSecondsLeft <= 0) {
        pairingTimer.stop();
        root.pairing = false;
        root.pairingError = "Pairing timed out.";
        return;
      }
      root._attemptPair();
    }
  }

  function startPairing(ip) {
    if (root.pairing)
      return;

    if (!ip || ip.trim() === "") {
      root.pairingError = "Enter a bridge IP first.";
      return;
    }

    Settings.data.hue.bridgeIp = ip.trim();
    root.pairing = true;
    root.pairingError = "";
    root.pairingSecondsLeft = 30;
    root._attemptPair();
    pairingTimer.start();
  }

  function cancelPairing() {
    pairingTimer.stop();
    root.pairing = false;
    root.pairingError = "";
  }

  function _attemptPair() {
    const request = new XMLHttpRequest();
    request.onreadystatechange = function () {
      if (request.readyState !== XMLHttpRequest.DONE)
        return;

      if (request.status !== 200) {
        // Bridge unreachable at this IP - stop retrying, surface the error immediately
        pairingTimer.stop();
        root.pairing = false;
        root.pairingError = "Bridge unreachable at that IP.";
        return;
      }

      try {
        const results = JSON.parse(request.responseText);
        const entry = Array.isArray(results) ? results[0] : null;

        if (entry && entry.success && entry.success.username) {
          pairingTimer.stop();
          root.pairing = false;
          root.pairingError = "";
          Settings.data.hue.username = entry.success.username;
          console.log("[Hue] Paired with bridge successfully");
          root.fetchGroups();
        } else if (entry && entry.error && entry.error.type === 101) {
          // Link button not pressed yet - keep waiting for the timer to retry
        } else if (entry && entry.error) {
          pairingTimer.stop();
          root.pairing = false;
          root.pairingError = entry.error.description || "Pairing failed.";
        }
      } catch (e) {
        console.warn("[Hue] Failed to parse pairing response:", e);
      }
    };

    request.onerror = function () {
      pairingTimer.stop();
      root.pairing = false;
      root.pairingError = "Bridge unreachable at that IP.";
    };

    request.open("POST", `http://${Settings.data.hue.bridgeIp}/api`);
    request.setRequestHeader("Content-Type", "application/json");
    request.send(JSON.stringify({
                                  "devicetype": "crux-shell#" + Quickshell.env("USER")
                                }));
  }

  // --------------------------------
  // Groups (rooms/zones)
  function fetchGroups() {
    if (!root.paired || root.fetchingGroups)
      return;

    root.fetchingGroups = true;
    root.groupsError = "";

    const request = new XMLHttpRequest();
    request.onreadystatechange = function () {
      if (request.readyState !== XMLHttpRequest.DONE)
        return;

      root.fetchingGroups = false;

      if (request.status !== 200) {
        root.groupsError = "Failed to fetch rooms/zones.";
        return;
      }

      try {
        const data = JSON.parse(request.responseText);
        if (Array.isArray(data) && data[0] && data[0].error) {
          root.groupsError = data[0].error.description || "Failed to fetch rooms/zones.";
          return;
        }

        const parsed = [];
        for (var groupId in data) {
          const g = data[groupId];
          if (!g || (g.type !== "Room" && g.type !== "Zone"))
            continue;
          const bri = (g.action && typeof g.action.bri === "number") ? g.action.bri : 0;
          parsed.push({
                        "groupId": groupId,
                        "name": g.name,
                        "on": !!(g.action && g.action.on),
                        "brightness01": bri / 254
                      });
        }
        root.groupsData = parsed;

        // Default to the first room/zone if none selected yet
        if (Settings.data.hue.selectedGroupId === "" && parsed.length > 0) {
          root.selectGroup(parsed[0].groupId, parsed[0].name);
        }
      } catch (e) {
        root.groupsError = "Failed to fetch rooms/zones.";
        console.warn("[Hue] Failed to parse groups response:", e);
      }
    };

    request.onerror = function () {
      root.fetchingGroups = false;
      root.groupsError = "Failed to fetch rooms/zones.";
    };

    request.open("GET", `http://${root.bridgeIp}/api/${root.username}/groups`);
    request.send();
  }

  // Persistent per-group object - identity is stable across brightness/on-off updates,
  // which are applied in place instead of rebuilding the groups list (that rebuilding
  // was the source of a reactive binding-loop + it hammered the bridge on every drag tick).
  component Group: QtObject {
    id: group

    required property var modelData
    property string groupId: modelData.groupId
    property string name: modelData.name
    property bool on: modelData.on
    property real brightness01: modelData.brightness01
    property color lastColor: "white"

    property real queuedBrightness01: -1

    readonly property Timer debounceTimer: Timer {
      interval: 120
      onTriggered: {
        if (group.queuedBrightness01 >= 0) {
          group._sendBrightness(group.queuedBrightness01);
          group.queuedBrightness01 = -1;
        }
      }
    }

    // Called continuously while the user drags the slider - cheap local update only
    function setBrightness(value01) {
      const clamped = Math.max(0, Math.min(1, value01));
      group.brightness01 = clamped;
      group.on = clamped > 0;
      group.queuedBrightness01 = clamped;
      debounceTimer.restart();
    }

    // Applies an RGB color immediately via the bulb's HSV support
    function setColor(rgbColor) {
      const hueFrac = Math.max(0, rgbColor.hsvHue); // -1 for achromatic (gray/white) - clamp to 0
      const hue = Math.round(hueFrac * 65535);
      const sat = Math.round(rgbColor.hsvSaturation * 254);

      group.lastColor = rgbColor;
      group.on = true;
      debounceTimer.stop();
      group.queuedBrightness01 = -1;
      group._sendState({
                          "on": true,
                          "hue": hue,
                          "sat": sat
                        });
    }

    function setOn(newOn) {
      group.on = newOn;
      debounceTimer.stop();
      group.queuedBrightness01 = -1;
      group._sendState({
                          "on": newOn
                        });
    }

    function _sendBrightness(value01) {
      const bri = Math.max(1, Math.round(value01 * 254));
      group._sendState({
                          "on": true,
                          "bri": bri
                        });
    }

    function _sendState(payload) {
      if (!root.paired)
        return;

      const request = new XMLHttpRequest();
      request.onreadystatechange = function () {
        if (request.readyState !== XMLHttpRequest.DONE)
          return;
        if (request.status !== 200) {
          console.warn("[Hue] Failed to update group", group.groupId, "status:", request.status);
        }
      };
      request.onerror = function () {
        console.warn("[Hue] Network error updating group", group.groupId);
      };
      request.open("PUT", `http://${root.bridgeIp}/api/${root.username}/groups/${group.groupId}/action`);
      request.setRequestHeader("Content-Type", "application/json");
      request.send(JSON.stringify(payload));
    }
  }

  Instantiator {
    id: groupInstantiator
    model: root.groupsData
    delegate: Group {}

    onObjectAdded: (index, object) => {
      var arr = root.groups.slice();
      arr.splice(index, 0, object);
      root.groups = arr;
    }
    onObjectRemoved: (index, object) => {
      var arr = root.groups.slice();
      arr.splice(index, 1);
      root.groups = arr;
    }
  }

  Component.onCompleted: {
    if (root.paired)
      fetchGroups();
  }
}
