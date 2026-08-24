import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons

ColumnLayout {
  id: root
  spacing: 14

  Text {
    text: "crux"
    color: Color.mOnSurface
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeL
    font.bold: true
  }

  GridLayout {
    columns: 2
    rowSpacing: 6
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

  RowLayout {
    Layout.topMargin: 8
    spacing: 10

    Rectangle {
      width: restartLabel.implicitWidth + 24
      height: 30
      radius: Style.radiusXS
      color: restartHover.hovered ? Color.mOutline : Color.mSurfaceVariant

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

  Text {
    text: "Reloads every widget and settings page — use after editing a .qml file by hand outside this session."
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeXS
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  Item {
    Layout.fillHeight: true
  }
}
