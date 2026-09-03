import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Read-only reference view of the live keybinds.lua — not parsed/editable,
// the Lua mixes too many call shapes to reliably summarize. Edit the file directly.
ColumnLayout {
  id: root
  spacing: 8

  readonly property string _path: (Quickshell.env ? Quickshell.env("HOME") : "") + "/.config/hypr/keybinds.lua"

  NText {
    tracking: true
    text: "~/.config/hypr/keybinds.lua (read-only — edit the file directly, then `hyprctl reload`)"
    color: Color.labelText
    size: NText.Size.Caption
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  FileView {
    id: file
    path: root._path
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferModule
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.surfaceContainer
      strokeColor: Color.outline
      strokeWidth: Tokens.borderModule
    }

    Flickable {
      anchors.fill: parent
      anchors.margins: 8
      contentWidth: width
      contentHeight: text.implicitHeight
      clip: true

      NText {
        mono: true
        id: text
        width: parent.width
        text: file.text()
        color: Color.surfaceText
        size: NText.Size.Caption
        wrapMode: Text.NoWrap
      }
    }
  }
}
