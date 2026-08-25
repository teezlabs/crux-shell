import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.SettingsPanel.Controls

ColumnLayout {
  id: root
  spacing: 20

  SettingsSection {
    title: "crux"

    GridLayout {
      columns: 2
      rowSpacing: 8
      columnSpacing: 16

      Text {
        text: "Config"
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
      }
      Text {
        text: Quickshell.shellDir
        color: Color.mOnSurface
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
      }

      Text {
        text: "Settings"
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
      }
      Text {
        text: Settings.settingsFile
        color: Color.mOnSurface
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
      }
    }
  }

  SettingsSection {
    title: "Reload"
    description: "Reloads every widget and settings page — use after editing a .qml file by hand outside this session."

    RowLayout {
      spacing: 10

      Rectangle {
        width: restartLabel.implicitWidth + 24
        height: 30
        radius: Style.radiusXS
        color: restartHover.hovered ? Color.alpha(Color.mPrimary, 0.16) : Color.mSurface
        border.color: Color.alpha(Color.mPrimary, 0.55)
        border.width: restartHover.hovered ? 1 : 0
        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }

        Text {
          id: restartLabel
          anchors.centerIn: parent
          text: "Restart crux"
          color: Color.mOnSurface
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
        }

        HoverHandler {
          id: restartHover
          cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
          onTapped: Quickshell.execDetached(["bash", "-c", "pkill -f 'qs -c crux'; sleep 0.5; nohup qs -c crux >/dev/null 2>&1 & disown"])
        }
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
