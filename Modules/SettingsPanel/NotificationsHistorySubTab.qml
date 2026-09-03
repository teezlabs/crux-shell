import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

Flickable {
  id: root
  clip: true
  contentWidth: width
  contentHeight: col.implicitHeight

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Retention"
    description: "How many past notifications Commons/Notifs.qml keeps for the history popup (SUPER-equivalent bar icon). Session-only, not written to disk."

    SettingRow {
      label: "History limit"
      NSlider {
        Layout.preferredWidth: 200
        from: 5
        to: 200
        stepSize: 5
        value: Settings.data.notifications.historyLimit
        onMoved: value => Settings.data.notifications.historyLimit = value
      }
      NText {
        text: Settings.data.notifications.historyLimit + " entries"
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }
  }

  SettingsSection {
    title: "History"
    description: Notifs.history.length + " stored"

    RowLayout {
      Layout.fillWidth: true

      Item {
        Layout.fillWidth: true
      }

      NText {
        tracking: true
        visible: Notifs.history.length > 0
        text: "CLEAR ALL"
        color: Color.error
        size: NText.Size.LabelXs

        HoverHandler {
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: Notifs.clearHistory()
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      NText {
        visible: Notifs.history.length === 0
        text: "No notifications yet"
        color: Color.labelText
        size: NText.Size.BodySm
      }

      Repeater {
        model: Notifs.history.slice(0, 20)

        delegate: Rectangle {
          id: rowItem
          required property var modelData
          Layout.fillWidth: true
          height: 30
          color: rowHover.hovered ? Color.surfaceContainerHigh : "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            NText {
              tracking: true
              text: (rowItem.modelData.appName || "").toUpperCase()
              color: Color.labelText
              size: NText.Size.LabelXs
              Layout.preferredWidth: 110
              elide: Text.ElideRight
            }

            NText {
              text: rowItem.modelData.summary || ""
              color: Color.surfaceText
              size: NText.Size.BodySm
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              text: "×"
              color: Color.labelText
              font.pixelSize: Tokens.bodyLgSize

              HoverHandler {
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: Notifs.removeFromHistory(rowItem.modelData.id)
              }
            }
          }

          HoverHandler {
            id: rowHover
          }
        }
      }

      NText {
        visible: Notifs.history.length > 20
        text: "+ " + (Notifs.history.length - 20) + " more — open the bar's notification history icon to see all"
        color: Color.labelText
        size: NText.Size.Caption
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
