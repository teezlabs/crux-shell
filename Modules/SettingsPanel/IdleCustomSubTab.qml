import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

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
        color: Color.labelText
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
            fillColor: Color.surfaceContainerHigh
            strokeColor: Color.outline
            strokeWidth: Tokens.borderModule
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
                color: Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodySmSize
                font.weight: Font.DemiBold
                selectByMouse: true
                onEditingFinished: root._update(entryRow.index, "name", text)
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
                  onTapped: root._remove(entryRow.index)
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              NText {
                text: "Timeout"
                color: Color.labelText
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
                color: Color.labelText
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
                  fillColor: Color.surface
                  strokeColor: cmdInput.activeFocus ? Color.primary : Color.outline
                  strokeWidth: Tokens.borderModule
                }

                TextInput {
                  id: cmdInput
                  anchors.fill: parent
                  anchors.leftMargin: 6
                  anchors.rightMargin: 6
                  verticalAlignment: Text.AlignVCenter
                  text: entryRow.modelData.command || ""
                  color: Color.surfaceText
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
                color: Color.labelText
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
                  fillColor: Color.surface
                  strokeColor: resumeInput.activeFocus ? Color.primary : Color.outline
                  strokeWidth: Tokens.borderModule
                }

                TextInput {
                  id: resumeInput
                  anchors.fill: parent
                  anchors.leftMargin: 6
                  anchors.rightMargin: 6
                  verticalAlignment: Text.AlignVCenter
                  text: entryRow.modelData.resumeCommand || ""
                  color: Color.surfaceText
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
