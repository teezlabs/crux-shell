import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls

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
      Text {
        text: Settings.data.notifications.historyLimit + " entries"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
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

      Text {
        visible: Notifs.history.length > 0
        text: "CLEAR ALL"
        color: Color.error
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking

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

      Text {
        visible: Notifs.history.length === 0
        text: "No notifications yet"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
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

            Text {
              text: (rowItem.modelData.appName || "").toUpperCase()
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
              Layout.preferredWidth: 110
              elide: Text.ElideRight
            }

            Text {
              text: rowItem.modelData.summary || ""
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
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

      Text {
        visible: Notifs.history.length > 20
        text: "+ " + (Notifs.history.length - 20) + " more — open the bar's notification history icon to see all"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
