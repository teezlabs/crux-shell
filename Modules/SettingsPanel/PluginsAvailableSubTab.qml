import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Plugins fetched from every enabled source's registry.json (see
// Commons/Plugins.qml) -- install copies just that plugin's own
// subdirectory out of its source repo into pluginsDir.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Available plugins"
      description: "Pulled from every enabled source in the Sources tab."

      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        NText {
          text: Plugins.fetching ? "Refreshing…" : (Settings.data.plugins.sources.length === 0 ? "No sources configured." : Plugins.availablePlugins.length + " plugin(s) found")
          color: Color.labelText
          size: NText.Size.BodySm
          Layout.fillWidth: true
        }

        Item {
          width: refreshLabel.implicitWidth + 24
          height: 28

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: refreshHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
            strokeColor: Color.outline
            strokeWidth: Tokens.borderModule
          }

          NText {
            id: refreshLabel
            anchors.centerIn: parent
            text: "Refresh"
            color: Color.surfaceText
            size: NText.Size.BodySm
          }
          HoverHandler {
            id: refreshHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: Plugins.refreshAvailable()
          }
        }
      }
    }

    NText {
      visible: Plugins.lastInstallError !== ""
      text: Plugins.lastInstallError
      color: Color.error
      size: NText.Size.Caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      Repeater {
        model: Plugins.availablePlugins

        delegate: Item {
          id: row
          required property var modelData
          readonly property bool busy: !!Plugins.installing[row.modelData.id]
          Layout.fillWidth: true
          height: 48

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Color.surfaceContainer
            strokeColor: Color.outline
            strokeWidth: Tokens.borderModule
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1
              NText {
                text: row.modelData.label || row.modelData.id
                color: Color.surfaceText
                size: NText.Size.BodySm
                elide: Text.ElideRight
              }
              NText {
                text: (row.modelData.description || "") + "  ·  " + (row.modelData.source ? row.modelData.source.name : "")
                color: Color.labelText
                size: NText.Size.Caption
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            Item {
              width: installLabel.implicitWidth + 20
              height: 26
              visible: !row.modelData.installed

              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: installHover.hovered ? Color.primaryContainer : Color.surfaceContainerHigh
                strokeColor: Color.primary
                strokeWidth: Tokens.borderModule
              }
              NText {
                tracking: true
                id: installLabel
                anchors.centerIn: parent
                text: row.busy ? "INSTALLING…" : "INSTALL"
                color: Color.primary
                size: NText.Size.LabelXs
              }
              HoverHandler {
                id: installHover
                cursorShape: Qt.PointingHandCursor
                enabled: !row.busy
              }
              TapHandler {
                enabled: !row.busy
                onTapped: Plugins.installPlugin(row.modelData)
              }
            }

            NText {
              tracking: true
              visible: row.modelData.installed
              text: "INSTALLED"
              color: Color.labelText
              size: NText.Size.LabelXs
            }
          }
        }
      }

      NText {
        visible: !Plugins.fetching && Plugins.availablePlugins.length === 0 && Settings.data.plugins.sources.length > 0
        text: "No plugins found from configured sources yet — try Refresh."
        color: Color.labelText
        size: NText.Size.BodySm
      }

      Repeater {
        model: Object.keys(Plugins.fetchErrors)
        delegate: Text {
          required property string modelData
          text: modelData + ": " + Plugins.fetchErrors[modelData]
          color: Color.error
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }
      }
    }

    Item {
      Layout.fillHeight: true
    }
  }
}
