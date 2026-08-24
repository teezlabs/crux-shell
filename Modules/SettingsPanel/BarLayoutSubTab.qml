import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons

ColumnLayout {
  id: root
  property string screenName: ""
  spacing: 16

  Text {
    text: "Position"
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeS
  }

  RowLayout {
    spacing: 6

    Repeater {
      model: ["top", "bottom", "left", "right"]
      delegate: Rectangle {
        required property string modelData
        Layout.preferredWidth: 80
        height: 30
        radius: Style.radiusXS
        color: Settings.data.bar.position === modelData ? Color.mPrimary : Color.mSurfaceVariant

        Text {
          anchors.centerIn: parent
          text: parent.modelData
          color: Settings.data.bar.position === parent.modelData ? Color.mOnPrimary : Color.mOnSurface
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Settings.data.bar.position = parent.modelData
        }
      }
    }
  }

  Text {
    text: "Widget spacing: " + Settings.data.bar.widgetSpacing + "px"
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeS
  }

  Slider {
    Layout.preferredWidth: 260
    from: 0
    to: 24
    stepSize: 1
    value: Settings.data.bar.widgetSpacing
    onMoved: Settings.data.bar.widgetSpacing = Math.round(value)
  }

  Text {
    text: "Content padding: " + Settings.data.bar.contentPadding + "px"
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeS
  }

  Slider {
    Layout.preferredWidth: 260
    from: 0
    to: 24
    stepSize: 1
    value: Settings.data.bar.contentPadding
    onMoved: Settings.data.bar.contentPadding = Math.round(value)
  }

  Text {
    text: "Monitors (empty = show on all)"
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeS
    Layout.topMargin: 8
  }

  ColumnLayout {
    spacing: 4

    Repeater {
      model: Quickshell.screens

      delegate: RowLayout {
        required property var modelData
        readonly property bool enabled_: Settings.data.bar.monitors.length === 0 || Settings.data.bar.monitors.includes(modelData.name)
        spacing: 8

        Rectangle {
          width: 18
          height: 18
          radius: Style.radiusXXS
          color: parent.enabled_ ? Color.mPrimary : "transparent"
          border.color: Color.mOutline
          border.width: 1

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              var list = Settings.data.bar.monitors.slice();
              var name = parent.parent.modelData.name;
              if (list.length === 0) {
                // Currently "all" — clicking one means "only the others".
                var all = [];
                for (var i = 0; i < Quickshell.screens.length; i++)
                  if (Quickshell.screens[i].name !== name)
                    all.push(Quickshell.screens[i].name);
                Settings.data.bar.monitors = all;
              } else {
                var idx = list.indexOf(name);
                if (idx >= 0)
                  list.splice(idx, 1);
                else
                  list.push(name);
                if (list.length === Quickshell.screens.length)
                  list = [];
                Settings.data.bar.monitors = list;
              }
            }
          }
        }

        Text {
          text: modelData.name
          color: Color.mOnSurface
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
        }
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
