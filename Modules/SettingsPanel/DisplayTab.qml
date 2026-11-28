import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Display tab: Monitors, Brightness and Night Light subtabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "brightness"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  // Keep-or-revert during a Monitors trial, above the subtabs so it stays in view however the page is scrolled.
  Item {
    visible: Monitors.trialActive
    Layout.fillWidth: true
    implicitHeight: trialRow.implicitHeight + Tokens.spaceMd * 2

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferModule
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Colors.alpha(Colors.primary, 0.1)
      strokeColor: Colors.primary
      strokeWidth: Tokens.borderModule
    }
    RowLayout {
      id: trialRow
      anchors.fill: parent
      anchors.margins: Tokens.spaceMd
      anchors.leftMargin: Tokens.spaceLg
      spacing: Tokens.spaceMd

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        NText {
          text: "KEEP THIS DISPLAY LAYOUT?"
          tracking: true
          size: NText.Size.LabelXs
          font.weight: Font.DemiBold
          color: Colors.primary
        }
        NText {
          text: "Going back in " + Monitors.trialRemaining + "s"
          size: NText.Size.BodySm
          color: Colors.surfaceText
        }
      }
      NButton {
        text: "Revert"
        onClicked: Monitors.revert()
      }
      NButton {
        text: "Keep"
        variant: "accent"
        onClicked: Monitors.keep()
      }
    }
  }

  NTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "brightness",
        "label": "Brightness"
      },
      {
        "id": "nightLight",
        "label": "Night Light"
      },
      {
        "id": "monitors",
        "label": "Monitors"
      }
    ]
    activeId: root.subTab
    onActivated: id => root.subTab = id
  }

  DisplayBrightnessSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "brightness"
  }

  DisplayNightLightSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "nightLight"
  }

  DisplayMonitorsSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "monitors"
  }
}
