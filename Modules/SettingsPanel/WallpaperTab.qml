import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.SettingsPanel.Controls

ColumnLayout {
  id: root
  spacing: 20

  SettingsSection {
    title: "Wallpaper"
    description: "The wallpaper directory is skwd-wall's own to manage — see ~/.config/skwd-wall/config.json \"paths.wallpaper\". Crux only tracks the current path below, set live whenever a wallpaper is applied."

    SettingRow {
      label: "Current"
      Text {
        text: Settings.data.wallpaper.path || "(none set)"
        color: Color.mOnSurface
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
        elide: Text.ElideMiddle
        Layout.fillWidth: true
      }
    }

    RowLayout {
      spacing: 10

      Rectangle {
        width: openLabel.implicitWidth + 24
        height: 30
        radius: Style.radiusXS
        color: openHover.hovered ? Color.alpha(Color.mPrimary, 0.16) : Color.mSurface
        border.color: Color.alpha(Color.mPrimary, 0.55)
        border.width: openHover.hovered ? 1 : 0
        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }

        Text {
          id: openLabel
          anchors.centerIn: parent
          text: "Open wallpaper picker"
          color: Color.mOnSurface
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
        }

        HoverHandler {
          id: openHover
          cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
          onTapped: Quickshell.execDetached(["qs", "-c", "skwd-wall"])
        }
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
