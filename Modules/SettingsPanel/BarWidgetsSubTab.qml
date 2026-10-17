import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Services

// Add, remove and reorder the bar's widgets per section. Long-press dragging
// on the bar itself (BarSection.qml) does the same moves live.
NScrollView {
  id: root
  property string screenName: ""
  contentHeight: col.implicitHeight

  readonly property var barWidgets: Settings.isLoaded ? Settings.getBarWidgetsForScreen(screenName) : ({
                                                                                                          "left": [],
                                                                                                          "center": [],
                                                                                                          "right": []
                                                                                                        })
  readonly property var sections: [
    {
      "id": "left",
      "title": "Start",
      "description": "Left on a horizontal bar, top on a vertical one."
    },
    {
      "id": "center",
      "title": "Center",
      "description": "Centred on the bar, and pushed aside if the ends grow into it."
    },
    {
      "id": "right",
      "title": "End",
      "description": "Right on a horizontal bar, bottom on a vertical one."
    }
  ]

  property string addId: ""
  property string addSection: "left"

  // "NotificationHistory" -> "Notification History"; acronyms like VPN stay whole.
  function displayName(id: string): string {
    return id.replace(/([a-z])([A-Z])/g, "$1 $2");
  }

  readonly property var addModel: BarWidgetRegistry.ids.concat(Plugins.ids).map(id => ({
                                                                                         "key": id,
                                                                                         "label": root.displayName(id)
                                                                                       }))

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Add a widget"
      description: "Pick a widget and the section it goes in. Long-press and drag on the bar to move widgets around live."

      RowLayout {
        spacing: Tokens.spaceMd

        NComboBox {
          Layout.preferredWidth: 220
          height: 28
          searchable: true
          popupMaxHeight: 260
          model: root.addModel
          currentKey: root.addId
          placeholder: "Choose a widget"
          onSelected: key => root.addId = key
        }

        NSegmented {
          model: root.sections.map(s => ({
                                           "key": s.id,
                                           "label": s.title
                                         }))
          currentKey: root.addSection
          onSelected: key => root.addSection = key
        }

        NButton {
          text: "Add"
          variant: "accent"
          enabled: root.addId !== ""
          opacity: enabled ? 1 : 0.4
          onClicked: Settings.addBarWidget(root.screenName, root.addSection, root.addId)
        }
      }
    }

    Repeater {
      model: root.sections

      delegate: SettingsSection {
        id: sectionBlock
        required property var modelData
        readonly property var widgets: root.barWidgets[modelData.id] || []
        Layout.fillWidth: true
        title: modelData.title + " · " + widgets.length
        description: modelData.description

        NText {
          visible: sectionBlock.widgets.length === 0
          text: "Nothing here yet."
          color: Colors.labelText
          size: NText.Size.BodySm
        }

        Repeater {
          model: sectionBlock.widgets

          delegate: Item {
            id: row
            required property var modelData
            required property int index
            Layout.fillWidth: true
            Layout.preferredHeight: 34

            Rectangle {
              anchors.fill: parent
              color: rowHover.hovered ? Colors.surfaceContainerHigh : "transparent"
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Tokens.spaceMd
              anchors.rightMargin: Tokens.spaceXs
              spacing: Tokens.spaceSm

              NText {
                text: root.displayName(row.modelData.id || "")
                color: Colors.surfaceText
                size: NText.Size.BodySm
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              NButton {
                text: "Up"
                textSize: NText.Size.LabelXs
                enabled: row.index > 0
                opacity: enabled ? 1 : 0.35
                onClicked: Settings.reorderBarWidget(root.screenName, sectionBlock.modelData.id, row.index, row.index - 1)
              }
              NButton {
                text: "Down"
                textSize: NText.Size.LabelXs
                enabled: row.index < sectionBlock.widgets.length - 1
                opacity: enabled ? 1 : 0.35
                onClicked: Settings.reorderBarWidget(root.screenName, sectionBlock.modelData.id, row.index, row.index + 1)
              }
              NButton {
                text: "Remove"
                variant: "destructive"
                textSize: NText.Size.LabelXs
                onClicked: Settings.removeBarWidget(root.screenName, sectionBlock.modelData.id, row.index)
              }
            }

            HoverHandler {
              id: rowHover
            }
          }
        }
      }
    }
  }
}
