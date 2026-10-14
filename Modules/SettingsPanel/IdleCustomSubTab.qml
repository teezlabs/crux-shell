import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets
import qs.Services

// Arbitrary user-defined idle commands, each with its own timeout and an
// optional resume command — noctalia's CustomSubTab.qml equivalent. Backed
// by Settings.data.idle.customCommands (a JSON-encoded array), applied live
// by Commons/Idle.qml's own dynamically-created IdleMonitor per entry.
NScrollView {
  id: root
  enabled: Settings.data.idle.enabled
  contentHeight: col.implicitHeight

  property var entries: []
  property bool _saving: false

  function _load() {
    if (root._saving)
      return;
    try {
      root.entries = JSON.parse(Settings.data.idle.customCommands);
    } catch (e) {
      root.entries = [];
    }
  }

  function _save() {
    root._saving = true;
    Settings.data.idle.customCommands = JSON.stringify(root.entries);
    root._saving = false;
  }

  function _update(index, key, value) {
    var next = root.entries.slice();
    next[index] = Object.assign({}, next[index]);
    next[index][key] = value;
    root.entries = next;
    root._save();
  }

  function _add() {
    var next = root.entries.slice();
    next.push({
      "name": "New command",
      "timeout": 300,
      "command": "",
      "resumeCommand": ""
    });
    root.entries = next;
    root._save();
  }

  function _remove(index) {
    var next = root.entries.slice();
    next.splice(index, 1);
    root.entries = next;
    root._save();
  }

  Component.onCompleted: _load()

  Connections {
    target: Settings.data.idle
    function onCustomCommandsChanged() {
      root._load();
    }
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Custom idle commands"
    description: "Each fires its own command after its own idle timeout, with an optional command to run again on activity."

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 10

      NText {
        visible: root.entries.length === 0
        text: "No custom commands yet."
        color: Colors.labelText
        size: NText.Size.BodySm
      }

      Repeater {
        model: root.entries

        delegate: Item {
          id: entryRow
          required property var modelData
          required property int index
          Layout.fillWidth: true
          height: entryCol.implicitHeight + 20

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Colors.surfaceContainerHigh
          }

          ColumnLayout {
            id: entryCol
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              TextInput {
                Layout.fillWidth: true
                text: entryRow.modelData.name || ""
                color: Colors.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodySmSize
                font.weight: Font.DemiBold
                selectByMouse: true
                onEditingFinished: root._update(entryRow.index, "name", text)
              }

              NText {
                tracking: true
                text: "REMOVE"
                color: Colors.error
                size: NText.Size.LabelXs

                HoverHandler {
                  cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                  onTapped: root._remove(entryRow.index)
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              NText {
                text: "Timeout"
                color: Colors.labelText
                size: NText.Size.Caption
              }

              NValueSlider {
                from: 5
                to: 3600
                stepSize: 5
                value: entryRow.modelData.timeout || 60
                sliderWidth: 160
                readoutText: (entryRow.modelData.timeout || 60) + "s"
                onMoved: value => root._update(entryRow.index, "timeout", value)
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              NText {
                text: "On idle"
                color: Colors.labelText
                size: NText.Size.Caption
                Layout.preferredWidth: 60
              }

              Item {
                Layout.fillWidth: true
                height: 24

                Chamfer {
                  anchors.fill: parent
                  chamferSize: Tokens.chamferIcon
                  cutTopRight: true
                  cutBottomLeft: true
                  fillColor: Colors.surface
                  strokeColor: Colors.primary
                  strokeWidth: cmdInput.activeFocus ? Tokens.borderModule : 0
                }

                TextInput {
                  id: cmdInput
                  anchors.fill: parent
                  anchors.leftMargin: 6
                  anchors.rightMargin: 6
                  verticalAlignment: Text.AlignVCenter
                  text: entryRow.modelData.command || ""
                  color: Colors.surfaceText
                  font.family: Tokens.fontFamily
                  font.pixelSize: Tokens.captionSize
                  selectByMouse: true
                  onEditingFinished: root._update(entryRow.index, "command", text)
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              NText {
                text: "On resume"
                color: Colors.labelText
                size: NText.Size.Caption
                Layout.preferredWidth: 60
              }

              Item {
                Layout.fillWidth: true
                height: 24

                Chamfer {
                  anchors.fill: parent
                  chamferSize: Tokens.chamferIcon
                  cutTopRight: true
                  cutBottomLeft: true
                  fillColor: Colors.surface
                  strokeColor: Colors.primary
                  strokeWidth: resumeInput.activeFocus ? Tokens.borderModule : 0
                }

                TextInput {
                  id: resumeInput
                  anchors.fill: parent
                  anchors.leftMargin: 6
                  anchors.rightMargin: 6
                  verticalAlignment: Text.AlignVCenter
                  text: entryRow.modelData.resumeCommand || ""
                  color: Colors.surfaceText
                  font.family: Tokens.fontFamily
                  font.pixelSize: Tokens.captionSize
                  selectByMouse: true
                  onEditingFinished: root._update(entryRow.index, "resumeCommand", text)
                }
              }
            }
          }
        }
      }

      NButton {
        height: 28
        text: "+ ADD COMMAND"
        textSize: NText.Size.LabelXs
        onClicked: root._add()
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
