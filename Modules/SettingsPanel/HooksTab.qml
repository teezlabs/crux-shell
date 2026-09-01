import QtQuick
import QtQuick.Layouts

// Top-level "Hooks" settings tab: General/Hooks as subtabs, same
// SubTabBar structure as IdleTab. Real backend is Commons/Hooks.qml —
// pre/post-action shell hooks, ported from noctalia-shell's HooksService.
// Noctalia's performance-mode pair of hooks was deliberately dropped (crux
// has no performance-mode concept; the Battery popup's power-profiles
// switcher is a different thing).
ColumnLayout {
  id: root
  spacing: 14

  property var targetScreen: null
  property string subTab: "general"

  SubTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "general",
        "label": "General"
      },
      {
        "id": "hooks",
        "label": "Hooks"
      }
    ]
    activeId: root.subTab
    onActiveIdChanged: root.subTab = activeId
  }

  HooksGeneralSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "general"
  }

  HooksListSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "hooks"
    targetScreen: root.targetScreen
  }
}
