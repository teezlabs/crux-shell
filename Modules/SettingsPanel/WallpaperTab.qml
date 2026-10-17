import QtQuick
import QtQuick.Layouts
import qs.Widgets

// Top-level "Wallpaper" settings tab. Was one 637-line page; the three
// subtabs below match the split every other multi-page tab already uses.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "library"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  NTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "library",
        "label": "Library"
      },
      {
        "id": "theme",
        "label": "Theme"
      },
      {
        "id": "transition",
        "label": "Transition"
      }
    ]
    activeId: root.subTab
    onActivated: id => root.subTab = id
  }

  WallpaperLibrarySubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "library"
  }

  WallpaperThemeSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "theme"
  }

  WallpaperTransitionSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "transition"
  }
}
