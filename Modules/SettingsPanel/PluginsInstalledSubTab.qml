import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets
import qs.Services

// Local-folder plugin discovery status — no marketplace, no install flow:
// a plugin is a directory you drop under Plugins.pluginsDir yourself (see
// Commons/Plugins.qml). This tab just shows what got found, so a bad
// manifest or a missing Widget.qml doesn't fail silently.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Plugins"
    description: "Drop a directory containing manifest.json ({\"id\": \"...\", \"label\": \"...\"}) and Widget.qml under the path below — it becomes selectable in Bar → Widgets, exactly like a built-in widget."

    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      NText {
        text: Plugins.pluginsDir
        color: Colors.surfaceText
        size: NText.Size.BodySm
        elide: Text.ElideMiddle
        Layout.fillWidth: true
      }

      NButton {
        height: 28
        text: "Rescan"
        onClicked: Plugins.rescan()
      }
    }
  }

  SettingsSection {
    title: "Discovered"
    description: "Every plugin found in that folder, and whether it loaded cleanly."

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      Repeater {
        model: Object.keys(Plugins.entries)

        delegate: Item {
          id: row
          required property string modelData
          readonly property var entry: Plugins.entries[modelData]
          Layout.fillWidth: true
          height: 36

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Colors.alpha(row.entry.error ? Colors.error : Colors.primary, 0.1)
            strokeColor: Colors.alpha(row.entry.error ? Colors.error : Colors.primary, 0.4)
            strokeWidth: Tokens.borderModule
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Text {
              text: row.entry.error ? "✕" : "✓"
              color: row.entry.error ? Colors.error : Colors.primary
              font.pixelSize: Tokens.bodySize
            }

            NText {
              text: row.entry.label || row.modelData
              color: Colors.surfaceText
              size: NText.Size.BodySm
              Layout.preferredWidth: 140
              elide: Text.ElideRight
            }

            NText {
              text: row.entry.error ? row.entry.error : row.entry.dir
              color: Colors.labelText
              size: NText.Size.Caption
              elide: Text.ElideMiddle
              Layout.fillWidth: true
            }
          }
        }
      }

      NText {
        visible: Object.keys(Plugins.entries).length === 0
        text: "No plugins found."
        color: Colors.labelText
        size: NText.Size.BodySm
      }

      NText {
        visible: Plugins.lastScanError !== ""
        text: Plugins.lastScanError
        color: Colors.error
        size: NText.Size.Caption
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }
  }
  }
}
