import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Git repos to pull plugin registries from -- each needs a registry.json
// at its root ({"plugins": [{"id","label","description",...}]}). Adding
// or enabling a source doesn't fetch anything by itself; the Available
// tab's own Refresh does that.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  property string newUrl: ""
  property string newName: ""

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Add a source"
      description: "A git repo URL — cloned shallow/sparse, only registry.json is ever fetched until you install something."

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: 30

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Color.surface
            strokeColor: urlInput.activeFocus ? Color.primary : Color.outline
            strokeWidth: Tokens.borderModule
          }

          NText {
            visible: urlInput.text === ""
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 8
            text: "https://github.com/user/crux-plugins"
            color: Color.labelText
            size: NText.Size.BodySm
          }

          TextInput {
            id: urlInput
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
            selectByMouse: true
            onTextChanged: root.newUrl = text
          }
        }
        RowLayout {
          Layout.fillWidth: true
          spacing: 8
          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 30

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Color.surface
              strokeColor: nameInput.activeFocus ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            NText {
              visible: nameInput.text === ""
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: 8
              text: "Display name (optional)"
              color: Color.labelText
              size: NText.Size.BodySm
            }

            TextInput {
              id: nameInput
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              verticalAlignment: Text.AlignVCenter
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
              selectByMouse: true
              onTextChanged: root.newName = text
            }
          }
          Item {
            width: addLabel.implicitWidth + 24
            height: 28

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: addHover.hovered ? Color.primaryContainer : Color.surfaceContainer
              strokeColor: Color.primary
              strokeWidth: Tokens.borderModule
            }
            NText {
              id: addLabel
              anchors.centerIn: parent
              text: "Add"
              color: Color.primary
              size: NText.Size.BodySm
            }
            HoverHandler {
              id: addHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: {
                if (root.newUrl.trim() === "")
                  return;
                var list = Settings.data.plugins.sources.slice();
                list.push({
                  "url": root.newUrl.trim(),
                  "name": root.newName.trim() || root.newUrl.trim(),
                  "enabled": true
                });
                Settings.data.plugins.sources = list;
                root.newUrl = "";
                root.newName = "";
                urlInput.text = "";
                nameInput.text = "";
              }
            }
          }
        }
      }
    }

    SettingsSection {
      title: "Sources"
      description: "Toggle a source off to stop it contributing to Available without deleting it."

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: Settings.data.plugins.sources

          delegate: Item {
            id: srcRow
            required property var modelData
            required property int index
            Layout.fillWidth: true
            height: 40

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Color.surfaceContainer
              strokeColor: srcRow.modelData.enabled === false ? Color.outline : Color.primary
              strokeWidth: Tokens.borderModule
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                NText {
                  text: srcRow.modelData.name || srcRow.modelData.url
                  color: Color.surfaceText
                  size: NText.Size.BodySm
                  elide: Text.ElideMiddle
                  Layout.fillWidth: true
                }
                NText {
                  text: srcRow.modelData.url
                  color: Color.labelText
                  size: NText.Size.Caption
                  elide: Text.ElideMiddle
                  Layout.fillWidth: true
                }
              }

              NToggle {
                checked: srcRow.modelData.enabled !== false
                onToggled: checked => {
                  var list = Settings.data.plugins.sources.slice();
                  list[srcRow.index] = Object.assign({}, list[srcRow.index], {
                    "enabled": checked
                  });
                  Settings.data.plugins.sources = list;
                }
              }

              NText {
                tracking: true
                text: "REMOVE"
                color: Color.error
                size: NText.Size.LabelXs
                HoverHandler {
                  cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                  onTapped: {
                    var list = Settings.data.plugins.sources.slice();
                    list.splice(srcRow.index, 1);
                    Settings.data.plugins.sources = list;
                  }
                }
              }
            }
          }
        }

        NText {
          visible: Settings.data.plugins.sources.length === 0
          text: "No sources yet."
          color: Color.labelText
          size: NText.Size.BodySm
        }
      }
    }

    Item {
      Layout.fillHeight: true
    }
  }
}
