import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

// Settings panel sidebar: fuzzy search box on top, tab list underneath.
// Typing swaps the tab list for matched entries; picking one emits
// jumpToSearchHit, which the window acts on.
ColumnLayout {
  id: panel

  // Supplied by SettingsWindow, which owns the search state.
  property var tabs: []
  property var searchResults: []
  property string searchQuery: ""
  property string activeTab: ""
  // Writes go out as signals rather than assignments back into a bound
  // property — an imperative write would destroy the binding from the
  // window and the two would silently stop tracking each other.
  signal jumpToSearchHit(var entry)
  signal searchQueryEdited(string text)
  signal tabSelected(string id)

  spacing: 2

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    Rectangle {
      anchors.fill: parent
      color: Colors.surfaceContainerLow
      border.color: Colors.outline
      border.width: Tokens.borderPanel
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 8
      spacing: 6

      Item {
        id: searchBox
        Layout.fillWidth: true
        Layout.preferredHeight: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Colors.surfaceContainer
          strokeColor: Colors.primary
          strokeWidth: searchInput.activeFocus ? Tokens.borderModule : 0
        }

        TextInput {
          id: searchInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: TextInput.AlignVCenter
          color: Colors.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          clip: true
          text: panel.searchQuery
          onTextChanged: panel.searchQueryEdited(text)

          NText {
            visible: searchInput.text === "" && !searchInput.activeFocus
            text: "Search settings…"
            color: Colors.labelText
            size: NText.Size.BodySm
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
          }
        }
      }

      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: panel.searchQuery.trim() === "" ? sidebarCol.implicitHeight : resultsCol.implicitHeight

        ColumnLayout {
          id: sidebarCol
          width: parent.width
          spacing: 4
          visible: panel.searchQuery.trim() === ""

          NText {
            tracking: true
            text: "SETTINGS"
            color: Colors.labelText
            size: NText.Size.LabelXs
            font.weight: Font.DemiBold
            Layout.bottomMargin: 10
            Layout.topMargin: 2
            Layout.leftMargin: 4
          }

          Repeater {
            model: panel.tabs

            delegate: Item {
              id: sidebarItem
              required property var modelData
              readonly property bool active: panel.activeTab === modelData.id
              Layout.fillWidth: true
              height: 32

              Rectangle {
                anchors.fill: parent
                color: sidebarItem.active ? Colors.primaryContainer : (tabHover.hovered ? Colors.surfaceContainerHigh : "transparent")
              }
              Rectangle {
                visible: sidebarItem.active
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Tokens.borderMarker
                color: Colors.primary
              }

              NText {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: sidebarItem.modelData.label
                color: sidebarItem.active ? Colors.primaryContainerText : Colors.surfaceText
                size: NText.Size.BodySm
                font.weight: sidebarItem.active ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
              }

              HoverHandler {
                id: tabHover
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: panel.tabSelected(sidebarItem.modelData.id)
              }
            }
          }
        }

        ColumnLayout {
          id: resultsCol
          width: parent.width
          spacing: 2
          visible: panel.searchQuery.trim() !== ""

          NText {
            tracking: true
            text: panel.searchResults.length === 0 ? "No matches" : panel.searchResults.length + " match" + (panel.searchResults.length === 1 ? "" : "es")
            color: Colors.labelText
            size: NText.Size.LabelXs
            Layout.bottomMargin: 10
            Layout.topMargin: 2
            Layout.leftMargin: 4
          }

          Repeater {
            model: panel.searchResults

            delegate: Item {
              id: resultItem
              required property var modelData
              Layout.fillWidth: true
              height: 40

              Rectangle {
                anchors.fill: parent
                color: resultHover.hovered ? Colors.surfaceContainerHigh : "transparent"
              }

              ColumnLayout {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                NText {
                  text: resultItem.modelData.label
                  color: Colors.surfaceText
                  size: NText.Size.BodySm
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }
                NText {
                  text: resultItem.modelData.description
                  color: Colors.labelText
                  size: NText.Size.Caption
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }
              }

              HoverHandler {
                id: resultHover
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: panel.jumpToSearchHit(resultItem.modelData)
              }
            }
          }
        }
      }
    }
  }
}
