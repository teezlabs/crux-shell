import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls

// Flickable, not ColumnLayout — content is taller than the settings card.
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
      description: "Which screen edge the bar sits on."

      RowLayout {
        spacing: 6

        Repeater {
          model: ["top", "bottom", "left", "right"]
          delegate: Item {
            id: posTile
            required property string modelData
            readonly property bool active: Settings.data.bar.position === modelData
            Layout.preferredWidth: 80
            height: 30

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: posTile.active ? Color.primaryContainer : (posHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
              strokeColor: posTile.active ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            Text {
              anchors.centerIn: parent
              text: posTile.modelData.toUpperCase()
              color: posTile.active ? Color.primaryContainerText : Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }

            HoverHandler {
              id: posHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: Settings.data.bar.position = posTile.modelData
            }
          }
        }
      }
    }

    SettingsSection {
      title: "Sizing"
      description: "Spacing, padding, and thickness of the bar and its modules."

      RowLayout {
        spacing: 10

        Text {
          text: "Density presets:"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
        }

        Repeater {
          model: [
            {
              "label": "Comfortable",
              "thickness": 32,
              "widgetSpacing": 6,
              "contentPadding": 2
            },
            {
              "label": "Compact",
              "thickness": 26,
              "widgetSpacing": 4,
              "contentPadding": 1
            }
          ]
          delegate: Item {
            id: densityTile
            required property var modelData
            Layout.preferredWidth: densityLabel.implicitWidth + 20
            height: 26

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: densityHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
              strokeColor: Color.outline
              strokeWidth: Tokens.borderModule
            }

            Text {
              id: densityLabel
              anchors.centerIn: parent
              text: densityTile.modelData.label
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }

            HoverHandler {
              id: densityHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: {
                Settings.data.bar.thickness = densityTile.modelData.thickness;
                Settings.data.bar.widgetSpacing = densityTile.modelData.widgetSpacing;
                Settings.data.bar.contentPadding = densityTile.modelData.contentPadding;
              }
            }
          }
        }
      }

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
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
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
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
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
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          Layout.preferredWidth: 34
        }
      }

      SettingRow {
        label: "Floating"
        NToggle {
          checked: Settings.data.bar.floating
          onToggled: checked => Settings.data.bar.floating = checked
        }
        Text {
          text: "Off = a real bar flush with the screen edge, ignoring the gap below"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
        }
      }

      SettingRow {
        label: "Floating gap"
        enabled: Settings.data.bar.floating
        opacity: enabled ? 1 : 0.4
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
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          Layout.preferredWidth: 34
        }
      }
    }

    SettingsSection {
      title: "Appearance"
      description: "Border, auto-hide, and background/opacity for the bar."

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
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
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
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
        }
      }

      SettingRow {
        label: "Background"
        NToggle {
          checked: Settings.data.bar.showBackground
          onToggled: checked => Settings.data.bar.showBackground = checked
        }
        NSlider {
          Layout.preferredWidth: 140
          Layout.leftMargin: 10
          enabled: Settings.data.bar.showBackground
          opacity: enabled ? 1 : 0.4
          from: 0.1
          to: 1
          stepSize: 0.05
          value: Settings.data.bar.barBackgroundOpacity
          onMoved: value => Settings.data.bar.barBackgroundOpacity = value
        }
        Text {
          text: Math.round(Settings.data.bar.barBackgroundOpacity * 100) + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          opacity: Settings.data.bar.showBackground ? 1 : 0.4
        }
      }

      SettingRow {
        label: "Separate opacity"
        NToggle {
          checked: Settings.data.bar.useSeparateOpacity
          onToggled: checked => Settings.data.bar.useSeparateOpacity = checked
        }
        NSlider {
          Layout.preferredWidth: 140
          Layout.leftMargin: 10
          enabled: Settings.data.bar.useSeparateOpacity
          opacity: enabled ? 1 : 0.4
          from: 0.1
          to: 1
          stepSize: 0.05
          value: Settings.data.bar.backgroundOpacity
          onMoved: value => Settings.data.bar.backgroundOpacity = value
        }
        Text {
          text: Math.round(Settings.data.bar.backgroundOpacity * 100) + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          opacity: Settings.data.bar.useSeparateOpacity ? 1 : 0.4
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
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
            }
          }
        }
      }
    }

    SettingsSection {
      title: "Per-monitor position override"
      description: "Give a specific monitor its own bar edge, different from the default above."

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
                color: Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodySmSize
              }
            }

            RowLayout {
              spacing: 6
              visible: overrideRow.isCustom
              Layout.leftMargin: 46

              Repeater {
                model: ["top", "bottom", "left", "right"]
                delegate: Item {
                  id: posBtn
                  required property string modelData
                  readonly property bool active: Settings.getBarPositionForScreen(overrideRow.screenName) === posBtn.modelData
                  Layout.preferredWidth: 64
                  height: 26

                  Chamfer {
                    anchors.fill: parent
                    chamferSize: Tokens.chamferIcon
                    cutTopRight: true
                    cutBottomLeft: true
                    fillColor: posBtn.active ? Color.primaryContainer : Color.surfaceContainer
                    strokeColor: posBtn.active ? Color.primary : Color.outline
                    strokeWidth: Tokens.borderModule
                  }

                  Text {
                    anchors.centerIn: parent
                    text: posBtn.modelData.toUpperCase()
                    color: posBtn.active ? Color.primaryContainerText : Color.surfaceText
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.labelXsSize
                    font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
                  }

                  HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                  }
                  TapHandler {
                    onTapped: Settings.setScreenOverride(overrideRow.screenName, "position", posBtn.modelData)
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
