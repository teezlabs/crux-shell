import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.SettingsPanel.Controls

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
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Position"

      RowLayout {
        spacing: 6

        Repeater {
          model: ["top", "bottom", "left", "right"]
          delegate: Rectangle {
            required property string modelData
            Layout.preferredWidth: 80
            height: 30
            radius: Style.radiusXS
            color: Settings.data.bar.position === modelData ? Color.mPrimary : (posHover.hovered ? Color.alpha(Color.mPrimary, 0.16) : Color.mSurface)
            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            Text {
              anchors.centerIn: parent
              text: parent.modelData
              color: Settings.data.bar.position === parent.modelData ? Color.mOnPrimary : Color.mOnSurface
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: Style.fontSizeS
            }

            HoverHandler {
              id: posHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: Settings.data.bar.position = parent.modelData
            }
          }
        }
      }
    }

    SettingsSection {
      title: "Sizing"

      SettingRow {
        label: "Widget spacing"
        NSlider {
          Layout.preferredWidth: 200
          from: 0
          to: 24
          stepSize: 1
          value: Settings.data.bar.widgetSpacing
          onMoved: value => Settings.data.bar.widgetSpacing = Math.round(value)
        }
        Text {
          text: Settings.data.bar.widgetSpacing + "px"
          color: Color.mOnSurfaceVariant
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
          Layout.preferredWidth: 34
        }
      }

      SettingRow {
        label: "Content padding"
        NSlider {
          Layout.preferredWidth: 200
          from: 0
          to: 24
          stepSize: 1
          value: Settings.data.bar.contentPadding
          onMoved: value => Settings.data.bar.contentPadding = Math.round(value)
        }
        Text {
          text: Settings.data.bar.contentPadding + "px"
          color: Color.mOnSurfaceVariant
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
          Layout.preferredWidth: 34
        }
      }

      SettingRow {
        label: "Thickness"
        NSlider {
          Layout.preferredWidth: 200
          from: 24
          to: 56
          stepSize: 1
          value: Settings.data.bar.thickness
          onMoved: value => Settings.data.bar.thickness = Math.round(value)
        }
        Text {
          text: Settings.data.bar.thickness + "px"
          color: Color.mOnSurfaceVariant
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
          Layout.preferredWidth: 34
        }
      }

      SettingRow {
        label: "Floating gap"
        NSlider {
          Layout.preferredWidth: 200
          from: 0
          to: 24
          stepSize: 1
          value: Settings.data.bar.floatMargin
          onMoved: value => Settings.data.bar.floatMargin = Math.round(value)
        }
        Text {
          text: Settings.data.bar.floatMargin + "px"
          color: Color.mOnSurfaceVariant
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
          Layout.preferredWidth: 34
        }
      }
    }

    SettingsSection {
      title: "Appearance"

      SettingRow {
        label: "Border"
        NToggle {
          checked: Settings.data.bar.showBorder
          onToggled: checked => Settings.data.bar.showBorder = checked
        }
        NSlider {
          Layout.preferredWidth: 140
          Layout.leftMargin: 10
          enabled: Settings.data.bar.showBorder
          opacity: enabled ? 1 : 0.4
          from: 1
          to: 4
          stepSize: 0.5
          value: Settings.data.bar.borderWidth
          onMoved: value => Settings.data.bar.borderWidth = value
        }
        Text {
          text: Settings.data.bar.borderWidth + "px"
          color: Color.mOnSurfaceVariant
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
          opacity: Settings.data.bar.showBorder ? 1 : 0.4
        }
      }

      SettingRow {
        label: "Auto-hide"
        NToggle {
          checked: Settings.data.bar.autoHide
          onToggled: checked => Settings.data.bar.autoHide = checked
        }
        Text {
          text: "Show only when the pointer touches the bar's edge"
          color: Color.mOnSurfaceVariant
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeXS
        }
      }
    }

    SettingsSection {
      title: "Monitors"
      description: "Which screens show the bar. Off on every monitor = show on all."

      ColumnLayout {
        spacing: 10

        Repeater {
          model: Quickshell.screens

          delegate: RowLayout {
            required property var modelData
            readonly property bool enabled_: Settings.data.bar.monitors.length === 0 || Settings.data.bar.monitors.includes(modelData.name)
            spacing: 10

            NToggle {
              checked: parent.enabled_
              onToggled: {
                var list = Settings.data.bar.monitors.slice();
                var name = parent.modelData.name;
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

            Text {
              text: modelData.name
              color: Color.mOnSurface
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: Style.fontSizeS
            }
          }
        }
      }
    }

    SettingsSection {
      title: "Per-monitor position override"

      ColumnLayout {
        spacing: 12

        Repeater {
          model: Quickshell.screens

          delegate: ColumnLayout {
            id: overrideRow
            required property var modelData
            readonly property string screenName: modelData.name
            readonly property bool isCustom: Settings.hasPositionOverride(screenName)
            spacing: 6

            RowLayout {
              spacing: 10

              NToggle {
                checked: overrideRow.isCustom
                onToggled: {
                  if (overrideRow.isCustom) {
                    Settings.setScreenOverride(overrideRow.screenName, "enabled", false);
                  } else {
                    Settings.setScreenOverride(overrideRow.screenName, "position", Settings.getBarPositionForScreen(overrideRow.screenName));
                    Settings.setScreenOverride(overrideRow.screenName, "enabled", true);
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
              Layout.leftMargin: 46

              Repeater {
                model: ["top", "bottom", "left", "right"]
                delegate: Rectangle {
                  id: posBtn
                  required property string modelData
                  Layout.preferredWidth: 64
                  height: 26
                  radius: Style.radiusXS
                  color: Settings.getBarPositionForScreen(overrideRow.screenName) === posBtn.modelData ? Color.mPrimary : Color.mSurface

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

    Item {
      Layout.preferredHeight: 4
    }
  }
}
