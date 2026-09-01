import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras

// Read-only reference view of the live Hyprland keybinds file — not a
// parsed/editable table. ~/.config/hypr/keybinds.lua mixes simple
// hl.bind(mod(...), ...) calls with loops, multi-line gesture blocks, and
// function() callbacks (see e.g. the ScrollOverview shift-scroll section);
// a regex parser robust enough to summarize all of that reliably isn't
// worth the fragility for a reference view. Edit the file directly to
// change bindings — Hyprland picks up `hyprctl reload` live.
ColumnLayout {
  id: root
  spacing: 8

  readonly property string _path: (Quickshell.env ? Quickshell.env("HOME") : "") + "/.config/hypr/keybinds.lua"

  Text {
    text: "~/.config/hypr/keybinds.lua (read-only — edit the file directly, then `hyprctl reload`)"
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.captionSize
    font.letterSpacing: Tokens.captionSize * Tokens.captionTracking
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

      Text {
        id: text
        width: parent.width
        text: file.text()
        color: Color.surfaceText
        font.family: Tokens.monoFontFamily
        font.pixelSize: Tokens.captionSize
        wrapMode: Text.NoWrap
      }
    }
  }
}
