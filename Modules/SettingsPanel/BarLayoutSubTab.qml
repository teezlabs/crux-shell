import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons

// Root is a Flickable, not a plain ColumnLayout — this subtab's content
// (position/spacing/thickness/gap/border/auto-hide/monitors/per-monitor
// overrides) grew past what fits in the settings card's fixed height, and
// a ColumnLayout alone has no scroll of its own. contentHeight tracks the
// inner ColumnLayout's implicitHeight so it scrolls exactly as far as it
// needs to, no further.
Flickable {
  id: root
  property string screenName: ""
  clip: true
  contentWidth: width
  contentHeight: col.implicitHeight

  ColumnLayout {
    id: col
    width: parent.width
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
    text: "Thickness: " + Settings.data.bar.thickness + "px"
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeS
  }

  Slider {
    Layout.preferredWidth: 260
    from: 24
    to: 56
    stepSize: 1
    value: Settings.data.bar.thickness
    onMoved: Settings.data.bar.thickness = Math.round(value)
  }

  Text {
    text: "Floating gap: " + Settings.data.bar.floatMargin + "px"
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeS
  }

  Slider {
    Layout.preferredWidth: 260
    from: 0
    to: 24
    stepSize: 1
    value: Settings.data.bar.floatMargin
    onMoved: Settings.data.bar.floatMargin = Math.round(value)
  }

  RowLayout {
    spacing: 10
    Layout.topMargin: 4

    Rectangle {
      width: 18
      height: 18
      radius: Style.radiusXXS
      color: Settings.data.bar.showBorder ? Color.mPrimary : "transparent"
      border.color: Color.mOutline
      border.width: 1

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Settings.data.bar.showBorder = !Settings.data.bar.showBorder
      }
    }

    Text {
      text: "Border"
      color: Color.mOnSurface
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
    }

    Slider {
      Layout.preferredWidth: 140
      Layout.leftMargin: 10
      enabled: Settings.data.bar.showBorder
      opacity: enabled ? 1 : 0.4
      from: 1
      to: 4
      stepSize: 0.5
      value: Settings.data.bar.borderWidth
      onMoved: Settings.data.bar.borderWidth = value
    }

    Text {
      text: Settings.data.bar.borderWidth + "px"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      opacity: Settings.data.bar.showBorder ? 1 : 0.4
    }
  }

  RowLayout {
    spacing: 10

    Rectangle {
      width: 18
      height: 18
      radius: Style.radiusXXS
      color: Settings.data.bar.autoHide ? Color.mPrimary : "transparent"
      border.color: Color.mOutline
      border.width: 1

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Settings.data.bar.autoHide = !Settings.data.bar.autoHide
      }
    }

    Text {
      text: "Auto-hide (show on hover)"
      color: Color.mOnSurface
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
    }
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

  Text {
    text: "Per-monitor position override"
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeS
    Layout.topMargin: 8
  }

  ColumnLayout {
    spacing: 8

    Repeater {
      model: Quickshell.screens

      delegate: ColumnLayout {
        id: overrideRow
        required property var modelData
        readonly property string screenName: modelData.name
        readonly property bool isCustom: Settings.hasPositionOverride(screenName)
        spacing: 4

        RowLayout {
          spacing: 8

          Rectangle {
            width: 18
            height: 18
            radius: Style.radiusXXS
            color: overrideRow.isCustom ? Color.mPrimary : "transparent"
            border.color: Color.mOutline
            border.width: 1

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (overrideRow.isCustom) {
                  Settings.setScreenOverride(overrideRow.screenName, "enabled", false);
                } else {
                  Settings.setScreenOverride(overrideRow.screenName, "position", Settings.getBarPositionForScreen(overrideRow.screenName));
                  Settings.setScreenOverride(overrideRow.screenName, "enabled", true);
                }
              }
            }
          }

          Text {
            text: overrideRow.screenName + " — custom position"
            color: Color.mOnSurface
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: Style.fontSizeS
          }
        }

        RowLayout {
          spacing: 6
          visible: overrideRow.isCustom
          Layout.leftMargin: 26

          Repeater {
            model: ["top", "bottom", "left", "right"]
            delegate: Rectangle {
              id: posBtn
              required property string modelData
              Layout.preferredWidth: 64
              height: 26
              radius: Style.radiusXS
              color: Settings.getBarPositionForScreen(overrideRow.screenName) === posBtn.modelData ? Color.mPrimary : Color.mSurfaceVariant

              Text {
                anchors.centerIn: parent
                text: posBtn.modelData
                color: Settings.getBarPositionForScreen(overrideRow.screenName) === posBtn.modelData ? Color.mOnPrimary : Color.mOnSurface
                font.family: Settings.data.ui.fontFamily
                font.pixelSize: Style.fontSizeXS
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Settings.setScreenOverride(overrideRow.screenName, "position", posBtn.modelData)
              }
            }
          }
        }
      }
    }
  }

  }
}
