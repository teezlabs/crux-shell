import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// Keep-or-revert prompt during a Monitors trial, on every screen where the settings window isn't open: a new layout
// can move it off view. Where it is open, the Display tab shows them above its subtabs, since a click on this separate
// window would count as outside the settings window and close it.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    // Popups doesn't notify, so look the settings window up when a trial starts, then follow its `visible`.
    property var settingsSurface: null
    Connections {
      target: Monitors
      function onTrialActiveChanged() {
        if (Monitors.trialActive)
          win.settingsSurface = Popups.find("settings", win.modelData);
      }
    }
    visible: Monitors.trialActive && !(win.settingsSurface && win.settingsSurface.visible)
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
