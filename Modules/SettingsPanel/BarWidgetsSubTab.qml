import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras

// Add/remove widgets per section as a list — complements the live
// drag-and-drop reordering directly on the bar (BarSection.qml), which
// already handles moving widgets between sections; this handles adding a
// new one or getting rid of one entirely.
RowLayout {
  id: root
  property string screenName: ""
  spacing: 16

  readonly property var barWidgets: Settings.isLoaded ? Settings.getBarWidgetsForScreen(screenName) : ({
                                                                                                          "left": [],
                                                                                                          "center": [],
                                                                                                          "right": []
                                                                                                        })
  readonly property var sections: [
    {
      "id": "left",
      "list": barWidgets.left
    },
    {
      "id": "center",
      "list": barWidgets.center
    },
    {
      "id": "right",
      "list": barWidgets.right
    }
  ]

  Repeater {
    model: root.sections

    delegate: ColumnLayout {
      id: sectionColumn
      required property var modelData
      readonly property string section: modelData.id
      readonly property var widgetsList: modelData.list
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 6

      Text {
        text: sectionColumn.section.toUpperCase()
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 160

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferModule
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Color.surfaceContainer
          strokeColor: Color.outline
          strokeWidth: Tokens.borderModule
        }

        ListView {
          anchors.fill: parent
          anchors.margins: 4
          clip: true
          spacing: 2
          model: sectionColumn.widgetsList

          delegate: Item {
            id: rowItem
            required property var modelData
            required property int index
            width: ListView.view.width
            height: 26

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 4
              anchors.rightMargin: 4

              Text {
                text: rowItem.modelData.id || ""
                color: Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodySmSize
                Layout.fillWidth: true
              }

              Item {
                width: 18
                height: 18

                Rectangle {
                  anchors.fill: parent
                  color: removeHover.hovered ? Color.alpha(Color.error, 0.2) : "transparent"
                }

                Text {
                  anchors.centerIn: parent
                  text: "×"
                  color: Color.error
                  font.pixelSize: Tokens.bodySize
                }

                HoverHandler {
                  id: removeHover
                  cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                  onTapped: Settings.removeBarWidget(root.screenName, sectionColumn.section, rowItem.index)
                }
              }
            }
          }
        }
      }

      Text {
        text: "ADD"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        Layout.topMargin: 4
      }

      Flow {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: BarWidgetRegistry.ids.concat(Plugins.ids)

          delegate: Item {
            id: addChip
            required property string modelData
            width: addLabel.implicitWidth + 12
            height: 20

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: addHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
              strokeColor: Color.outline
              strokeWidth: Tokens.borderModule
            }

            Text {
              id: addLabel
              anchors.centerIn: parent
              text: addChip.modelData
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
            }

            HoverHandler {
              id: addHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: Settings.addBarWidget(root.screenName, sectionColumn.section, addChip.modelData)
            }
          }
        }
      }

      Item {
        Layout.fillHeight: true
      }
    }
  }
}
