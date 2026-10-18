import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Commons
import qs.Services
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Not a full network-manager UI — just autoconnect priority and Bluetooth
// discoverability, the two things the Wifi/Bluetooth popups don't expose.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  readonly property var savedNetworks: NetworkManager.wifiConnections.slice().sort((a, b) => a.active !== b.active ? (a.active ? -1 : 1) : a.name.localeCompare(b.name))

  readonly property var btAdapter: Bluetooth.defaultAdapter

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Saved Wi-Fi networks"
    description: "Autoconnect priority (higher connects first when more than one saved network is in range) and removal — live scan/connect/forget for nearby networks are in the WI-FI popup, not here."

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        model: root.savedNetworks

        delegate: Item {
          id: netRow
          required property var modelData
          Layout.fillWidth: true
          height: 40

          Rectangle {
            anchors.fill: parent
            color: netHover.hovered ? Colors.surfaceContainerHigh : "transparent"
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 10

            Text {
              text: netRow.modelData.active ? "●" : "○"
              color: netRow.modelData.active ? Colors.primary : Colors.labelText
              font.pixelSize: Tokens.bodySmSize
            }

            NText {
              text: netRow.modelData.name
              color: Colors.surfaceText
              size: NText.Size.BodySm
              elide: Text.ElideRight
              Layout.preferredWidth: 160
            }

            NToggle {
              checked: netRow.modelData.autoconnect
              onToggled: checked => NetworkManager.setAutoconnect(netRow.modelData.uuid, checked)
            }
            NText {
              tracking: true
              text: "AUTO"
              color: Colors.labelText
              size: NText.Size.LabelXs
            }

            NValueSlider {
              from: -10
              to: 10
              stepSize: 1
              value: netRow.modelData.priority
              sliderWidth: 100
              readoutWidth: 26
              readoutText: (netRow.modelData.priority > 0 ? "+" : "") + netRow.modelData.priority
              onMoved: value => NetworkManager.setPriority(netRow.modelData.uuid, Math.round(value))
            }

            Item {
              Layout.fillWidth: true
            }

            Text {
              text: "×"
              color: forgetHover.hovered ? Colors.error : Colors.labelText
              font.pixelSize: Tokens.bodyLgSize
              HoverHandler {
                id: forgetHover
                cursorShape: Qt.PointingHandCursor
              }
              MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: NetworkManager.forget(netRow.modelData.uuid)
              }
            }
          }

          HoverHandler {
            id: netHover
          }
        }
      }

      NText {
        visible: root.savedNetworks.length === 0
        text: "No saved Wi-Fi networks (nmcli connection show)."
        color: Colors.labelText
        size: NText.Size.BodySm
      }
    }
  }

  SettingsSection {
    title: "Bluetooth"
    description: "Device pairing/connecting/forgetting is in the BLUETOOTH popup — this is the one adapter setting nothing else exposes."

    SettingRow {
      label: "Discoverable"
      enabled: !!root.btAdapter
      NToggle {
        checked: !!(root.btAdapter && root.btAdapter.discoverable)
        onToggled: checked => {
          if (root.btAdapter)
            root.btAdapter.discoverable = checked;
        }
      }
      NText {
        text: root.btAdapter ? "Other devices can see this machine while on" : "No adapter"
        color: Colors.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      label: "Hide unnamed devices"
      NToggle {
        checked: Settings.data.bluetooth.hideUnnamedDevices
        onToggled: checked => Settings.data.bluetooth.hideUnnamedDevices = checked
      }
      NText {
        text: "Off shows devices still using a raw address/UUID as their name (useful mid-pairing)"
        color: Colors.labelText
        size: NText.Size.Caption
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }
  }
  }
}
