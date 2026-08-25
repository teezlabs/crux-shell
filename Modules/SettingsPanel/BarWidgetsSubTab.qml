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
        text: sectionColumn.section
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
        font.capitalization: Font.AllUppercase
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 160
        radius: Style.radiusXS
        color: Color.mSurfaceVariant

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
                color: Color.mOnSurface
                font.family: Settings.data.ui.fontFamily
                font.pixelSize: Style.fontSizeS
                Layout.fillWidth: true
              }

              Text {
                text: "×"
                color: Color.mError
                font.pixelSize: Style.fontSizeM
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Settings.removeBarWidget(root.screenName, sectionColumn.section, rowItem.index)
                }
              }
            }
          }
        }
      }

      Text {
        text: "add"
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeXS
        Layout.topMargin: 4
      }

      Flow {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: BarWidgetRegistry.ids

          delegate: Rectangle {
            id: addChip
            required property string modelData
            width: addLabel.implicitWidth + 12
            height: 20
            radius: Style.radiusXXS
            color: addMouse.containsMouse ? Color.alpha(Color.mPrimary, 0.16) : Color.mSurfaceVariant
            border.color: Color.alpha(Color.mPrimary, 0.55)
            border.width: 1
            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            Text {
              id: addLabel
              anchors.centerIn: parent
              text: addChip.modelData
              color: Color.mOnSurfaceVariant
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: Style.fontSizeXS
            }

            MouseArea {
              id: addMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Settings.addBarWidget(root.screenName, sectionColumn.section, addChip.modelData)
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
