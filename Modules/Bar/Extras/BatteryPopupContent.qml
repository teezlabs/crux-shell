import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.Commons

// Battery detail popup content: percent/status, health, and a
// power-profile switcher via PowerProfiles (no-op if the daemon isn't
// running). Hosted inside a SlideCard by PopupHost.qml — no
// window/positioning of its own. Self-derived from UPower directly
// (same data Battery.qml's bar widget computes), not passed in, since
// content and widget now live in separate window trees.
ColumnLayout {
  id: root

  spacing: 12

  readonly property var device: UPower.displayDevice
  readonly property bool present: !!device && device.isPresent === true
  readonly property int percent: present ? Math.round((device.percentage || 0) * 100) : 0
  readonly property bool charging: present && device.state === UPowerDeviceState.Charging
  readonly property bool pluggedIn: present && (device.state === UPowerDeviceState.FullyCharged || device.state === UPowerDeviceState.PendingCharge)
  readonly property bool low: present && !charging && !pluggedIn && percent <= Settings.data.battery.lowThreshold && percent > Settings.data.battery.criticalThreshold
  readonly property bool critical: present && !charging && !pluggedIn && percent <= Settings.data.battery.criticalThreshold
  readonly property color statusColor: root.critical ? Color.error : (root.low ? Color.tertiary : (root.charging ? Color.primary : Color.surfaceText))

  function formatDuration(seconds) {
    var mins = Math.round(seconds / 60);
    var h = Math.floor(mins / 60);
    var m = mins % 60;
    return h > 0 ? h + "h " + m + "m" : m + "m";
  }

  readonly property string statusText: {
    if (!root.present)
      return "";
    if (root.pluggedIn)
      return "Plugged in";
    if (root.charging && device.timeToFull > 0)
      return "Full in " + root.formatDuration(device.timeToFull);
    if (!root.charging && device.timeToEmpty > 0)
      return root.formatDuration(device.timeToEmpty) + " remaining";
    return root.charging ? "Charging" : "On battery";
  }

  readonly property bool healthKnown: !!device && device.healthSupported === true

  readonly property var profileOptions: [
    {
      "key": PowerProfile.PowerSaver,
      "label": "SAVER"
    },
    {
      "key": PowerProfile.Balanced,
      "label": "BALANCED"
    },
    {
      "key": PowerProfile.Performance,
      "label": "PERF"
    }
  ]

  Text {
    text: "BATTERY"
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.labelXsSize
    font.weight: Font.DemiBold
    font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 10

    Text {
      text: root.percent + "%"
      color: root.statusColor
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.titleSize
      font.weight: Font.Light
    }

    Text {
      text: root.statusText
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
    }
  }

  SegMeter {
    Layout.fillWidth: true
    cellCount: Tokens.meterControlCenterCells
    cellHeight: Tokens.meterControlCenterCellHeight
    value: root.percent
    filledColor: root.statusColor
    emptyColor: Color.surfaceContainerHigh
  }

  RowLayout {
    Layout.fillWidth: true
    visible: root.healthKnown
    spacing: 6

    Text {
      text: "HEALTH"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
    Item {
      Layout.fillWidth: true
    }
    Text {
      text: root.healthKnown ? Math.round(root.device.healthPercentage) + "%" : ""
      color: Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
    }
  }

  Text {
    text: "POWER PROFILE"
    visible: Settings.data.battery.showPowerProfile
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.labelXsSize
    font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    Layout.topMargin: 4
  }

  RowLayout {
    Layout.fillWidth: true
    visible: Settings.data.battery.showPowerProfile
    spacing: 6

    Repeater {
      model: root.profileOptions

      delegate: Item {
        id: profileTile
        required property var modelData
        readonly property bool active: PowerProfiles.profile === modelData.key
        Layout.fillWidth: true
        height: 26

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: profileTile.active ? Color.primaryContainer : (profileHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
          strokeColor: profileTile.active ? Color.primary : Color.outline
          strokeWidth: Tokens.borderModule
        }

        Text {
          anchors.centerIn: parent
          text: profileTile.modelData.label
          color: profileTile.active ? Color.primaryContainerText : Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }

        HoverHandler {
          id: profileHover
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: PowerProfiles.profile = profileTile.modelData.key
        }
      }
    }
  }
}
