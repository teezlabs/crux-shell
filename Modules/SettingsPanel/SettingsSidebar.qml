import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

// Search box over the tab list; typing swaps in matches, and picking one emits jumpToSearchHit.
ColumnLayout {
  id: panel

  // Supplied by SettingsWindow, which owns the search state.
  property var tabs: []
  property var searchResults: []
  property string searchQuery: ""
  property string activeTab: ""
  // Signals rather than writes, which would break the window's bindings.
  signal jumpToSearchHit(var entry)
  signal searchQueryEdited(string text)
  signal tabSelected(string id)

  function focusSearch(): void {
    searchInput.forceActiveFocus();
    searchInput.selectAll();
  }

  spacing: 2

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutBottomLeft: true
      fillColor: Colors.surfaceContainerLow
      strokeColor: Colors.outline
      strokeWidth: Tokens.borderPanel
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 8
      spacing: 6

      Item {
        id: searchBox
        Layout.fillWidth: true
        Layout.preferredHeight: 32

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Colors.surfaceContainer
          strokeColor: searchInput.activeFocus ? Colors.primary : Colors.outline
          strokeWidth: Tokens.borderModule
        }

        NIcon {
          id: searchIcon
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          width: 14
          height: 14
          iconName: "search"
          color: Colors.labelText
        }

        NText {
          id: shortcutHint
          anchors.right: parent.right
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          visible: searchInput.text === "" && !searchInput.activeFocus
          text: "/"
          tracking: true
          color: Colors.labelText
          size: NText.Size.LabelXs
        }

        TextInput {
          id: searchInput
          anchors.fill: parent
          anchors.leftMargin: 32
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
            text: "Search"
            color: Colors.labelText
            size: NText.Size.BodySm
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
          }
        }
      }

      Flickable {
        id: scrollView
        layer.enabled: scrollFade.active
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: scrollFade
          maskThresholdMin: 0.5
          maskSpreadAtMin: 1
        }
        NSmoothWheel {
          flickable: scrollView
        }
        NScrollFade {
          id: scrollFade
          flickable: scrollView
        }
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: panel.searchQuery.trim() === "" ? sidebarCol.implicitHeight : resultsCol.implicitHeight

        ColumnLayout {
          id: sidebarCol
          width: parent.width
          spacing: 2
          visible: panel.searchQuery.trim() === ""

          Repeater {
            model: panel.tabs

            delegate: ColumnLayout {
              id: sidebarEntry
              required property var modelData
              required property int index
              readonly property bool startsSection: modelData.section !== "" && (index === 0 || panel.tabs[index - 1].section !== modelData.section)
              Layout.fillWidth: true
              spacing: 0

              NText {
                visible: sidebarEntry.startsSection
                tracking: true
                text: sidebarEntry.modelData.section.toUpperCase()
                color: Colors.labelText
                size: NText.Size.LabelXs
                font.weight: Font.DemiBold
                Layout.topMargin: sidebarEntry.index === 0 ? 2 : Tokens.spaceLg
                Layout.bottomMargin: Tokens.spaceSm
                Layout.leftMargin: 4
              }

              Item {
                id: sidebarItem
                readonly property var modelData: sidebarEntry.modelData
                readonly property bool active: panel.activeTab === modelData.id
                Layout.fillWidth: true
                Layout.preferredHeight: 32

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

                NIcon {
                  id: tabIcon
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  width: 16
                  height: 16
                  iconName: sidebarItem.modelData.icon || ""
                  color: sidebarItem.active ? Colors.primaryContainerText : Colors.surfaceTextMuted
                }

                NText {
                  anchors.left: tabIcon.right
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
