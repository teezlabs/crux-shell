import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons

ColumnLayout {
  id: root
  spacing: 14

  RowLayout {
    spacing: 10
    Text {
      text: "Directory"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      Layout.preferredWidth: 90
    }
    TextInput {
      Layout.fillWidth: true
      text: Settings.data.wallpaper.directory
      color: Color.mOnSurface
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      onEditingFinished: Settings.data.wallpaper.directory = text

      Rectangle {
        z: -1
        anchors.fill: parent
        anchors.margins: -4
        color: Color.mSurfaceVariant
        radius: Style.radiusXXS
      }
    }
  }

  Text {
    text: "skwd-wall's own ~/.config/skwd-wall/config.json \"paths.wallpaper\" is the actual source of truth for the picker — keep them in sync by hand for now."
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
