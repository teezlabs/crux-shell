import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// Keep-or-revert prompt during a Monitors trial, on every screen: a new layout can move the settings window off view.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    visible: Monitors.trialActive
    color: "transparent"
    implicitWidth: card.width
    implicitHeight: card.height

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "crux-monitors-confirm"
    exclusionMode: ExclusionMode.Ignore

    Item {
      id: card
      width: row.implicitWidth + Tokens.spaceXl * 2
      height: row.implicitHeight + Tokens.spaceLg * 2

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferPanel
        cutTopRight: true
        cutBottomLeft: true
        fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
        strokeColor: Colors.primary
        strokeWidth: Tokens.borderPanel
      }

      RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Tokens.spaceLg

        ColumnLayout {
          spacing: Tokens.spaceXs
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
  }
}
