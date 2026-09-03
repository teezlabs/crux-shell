import QtQuick
import QtQuick.Layouts
import qs.Commons

// A row of chamfered pills where exactly one is selected — the picker
// shape the settings panel uses for bar position, OSD position, temperature
// unit and so on.
//
// NTabBar is the same visual language but owns navigation state; this owns
// a value and reports changes, so a call site can bind it straight to a
// setting.
RowLayout {
  id: root

  // ["top", "bottom"] or [{key, label}] — a bare string is its own key.
  property var model: []
  property string currentKey: ""
  property real tileWidth: 70
  property real tileHeight: 28
  property bool uppercase: true

  signal selected(string key)

  readonly property var entries: {
    const out = [];
    for (const item of root.model || []) {
      if (item === null || item === undefined)
        continue;
      if (typeof item === "string")
        out.push({
          "key": item,
          "label": item
        });
      else
        out.push({
          "key": item.key !== undefined ? item.key : item.id,
          "label": item.label !== undefined ? item.label : (item.key !== undefined ? item.key : item.id)
        });
    }
    return out;
  }

  spacing: 6

  Repeater {
    model: root.entries

    delegate: Item {
      id: tile
      required property var modelData
      readonly property bool active: root.currentKey === tile.modelData.key

      Layout.preferredWidth: root.tileWidth
      Layout.preferredHeight: root.tileHeight
      implicitWidth: root.tileWidth
      implicitHeight: root.tileHeight

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferIcon
        cutTopRight: true
        cutBottomLeft: true
        fillColor: tile.active ? Color.primaryContainer : (tileHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
        strokeColor: tile.active ? Color.primary : Color.outline
        strokeWidth: Tokens.borderModule
      }

      NText {
        anchors.centerIn: parent
        text: root.uppercase ? String(tile.modelData.label).toUpperCase() : tile.modelData.label
        size: NText.Size.LabelXs
        tracking: true
        color: tile.active ? Color.primaryContainerText : Color.surfaceText
      }

      HoverHandler {
        id: tileHover
        cursorShape: Qt.PointingHandCursor
      }
      TapHandler {
        onTapped: {
          root.currentKey = tile.modelData.key;
          root.selected(tile.modelData.key);
        }
      }
    }
  }
}
