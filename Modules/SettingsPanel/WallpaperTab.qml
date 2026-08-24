import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons

ColumnLayout {
  id: root
  spacing: 14

  Text {
    text: "The wallpaper directory is skwd-wall's own to manage — see ~/.config/skwd-wall/config.json \"paths.wallpaper\". Crux only tracks the current path below, set live whenever a wallpaper is applied."
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeXS
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  RowLayout {
    spacing: 10
    Layout.topMargin: 4
    Text {
      text: "Current"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      Layout.preferredWidth: 90
    }
    Text {
      text: Settings.data.wallpaper.path || "(none set)"
      color: Color.mOnSurface
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      elide: Text.ElideMiddle
      Layout.fillWidth: true
    }
  }

  Rectangle {
    Layout.topMargin: 8
    width: openLabel.implicitWidth + 24
    height: 30
    radius: Style.radiusXS
    color: openHover.hovered ? Color.mOutline : Color.mSurfaceVariant

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

  Item {
    Layout.fillHeight: true
  }
}
