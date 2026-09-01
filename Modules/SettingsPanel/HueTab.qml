import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls

Flickable {
  id: root
  clip: true
  contentWidth: width
  contentHeight: col.implicitHeight

  property string ipField: Settings.data.hue.bridgeIp

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Bridge"
    description: Hue.paired ? "Paired with bridge at " + Settings.data.hue.bridgeIp + "." : "Not paired yet."

    SettingRow {
      Layout.fillWidth: true
      label: "Bridge IP"
      visible: !Hue.paired

      Item {
        Layout.fillWidth: true
        height: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Color.surface
          strokeColor: ipInput.activeFocus ? Color.primary : Color.outline
          strokeWidth: Tokens.borderModule
        }

        TextInput {
          id: ipInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: Text.AlignVCenter
          text: root.ipField
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          selectByMouse: true
          onTextChanged: root.ipField = text
        }
      }

      Rectangle {
        implicitWidth: discoverLabel.implicitWidth + 20
        implicitHeight: 28
        color: "transparent"
        border.width: Tokens.borderModule
        border.color: Color.outline

        Text {
          id: discoverLabel
          anchors.centerIn: parent
          text: Hue.discovering ? "…" : "Discover"
          color: (Hue.discovering || Hue.pairing) ? Color.disabledText : Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }

        HoverHandler {
          enabled: !Hue.discovering && !Hue.pairing
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          enabled: !Hue.discovering && !Hue.pairing
          onTapped: Hue.discoverBridge()
        }
      }
    }

    Text {
      Layout.fillWidth: true
      visible: Hue.discoveryError !== ""
      text: Hue.discoveryError
      color: Color.error
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
      wrapMode: Text.WordWrap
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 10
      visible: !Hue.paired && !Hue.pairing

      Item {
        Layout.fillWidth: true
      }

      Rectangle {
        implicitWidth: pairLabel.implicitWidth + 20
        implicitHeight: 28
        color: root.ipField.trim() !== "" ? Color.primaryContainer : Color.surfaceContainerHigh
        border.width: Tokens.borderModule
        border.color: root.ipField.trim() !== "" ? Color.primary : Color.outline

        Text {
          id: pairLabel
          anchors.centerIn: parent
          text: "Pair"
          color: root.ipField.trim() !== "" ? Color.primaryContainerText : Color.disabledText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }

        HoverHandler {
          enabled: root.ipField.trim() !== ""
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          enabled: root.ipField.trim() !== ""
          onTapped: Hue.startPairing(root.ipField)
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 10
      visible: Hue.pairing

      Text {
        Layout.fillWidth: true
        text: "Press the bridge's link button… (" + Hue.pairingSecondsLeft + "s)"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
        wrapMode: Text.WordWrap
      }

      Text {
        text: "Cancel"
        color: Color.error
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking

        HoverHandler {
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: Hue.cancelPairing()
        }
      }
    }

    Text {
      Layout.fillWidth: true
      visible: Hue.pairingError !== ""
      text: Hue.pairingError
      color: Color.error
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
      wrapMode: Text.WordWrap
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 10
      visible: Hue.paired

      Item {
        Layout.fillWidth: true
      }

      Text {
        text: "Forget"
        color: Color.error
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking

        HoverHandler {
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: Hue.forget()
        }
      }
    }
  }

  SettingsSection {
    title: "Rooms & zones"
    description: "Which room or zone the bar's Hue widget controls."
    visible: Hue.paired

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      Repeater {
        model: Hue.groups

        delegate: Rectangle {
          id: groupRow
          required property var modelData
          Layout.fillWidth: true
          height: 34
          readonly property bool isSelected: Settings.data.hue.selectedGroupId === modelData.groupId
          color: groupRow.isSelected ? Color.primaryContainer : (hoverGroup.hovered ? Color.surfaceContainerHigh : "transparent")

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            Text {
              text: groupRow.isSelected ? "●" : "○"
              color: groupRow.isSelected ? Color.primary : Color.labelText
              font.pixelSize: Tokens.bodySize
            }

            Text {
              text: groupRow.modelData.name
              color: groupRow.isSelected ? Color.primaryContainerText : Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          HoverHandler {
            id: hoverGroup
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: Hue.selectGroup(groupRow.modelData.groupId, groupRow.modelData.name)
          }
        }
      }

      Text {
        visible: Hue.groups.length === 0
        text: "No rooms/zones found."
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    RowLayout {
      Layout.fillWidth: true

      Item {
        Layout.fillWidth: true
      }

      Text {
        text: Hue.fetchingGroups ? "Refreshing…" : "Refresh"
        color: Hue.fetchingGroups ? Color.disabledText : Color.primary
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking

        HoverHandler {
          enabled: !Hue.fetchingGroups
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          enabled: !Hue.fetchingGroups
          onTapped: Hue.fetchGroups()
        }
      }
    }

    Text {
      Layout.fillWidth: true
      visible: Hue.groupsError !== ""
      text: Hue.groupsError
      color: Color.error
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
      wrapMode: Text.WordWrap
    }
  }
  }
}
