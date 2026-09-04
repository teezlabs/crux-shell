import QtQuick
import QtQuick.Layouts
import qs.Commons

// A row of chamfered chips where any number can be on — monitor pickers,
// notification-urgency filters, wallpaper transition choices.
//
// NSegmented is the one-of-N version of the same shape.
Flow {
  id: root

  // ["a","b"] or [{key, label}] — a bare string is its own key.
  property var model: []
  property var selected: []
  // Several settings treat an empty list as "everything", so a fresh
  // config isn't a config that does nothing.
  property bool emptyMeansAll: false
  // Some rows must keep at least one chip on — a wallpaper transition list
  // with nothing selected has no transition to pick from.
  property int minSelected: 0
  property real chipHeight: 28
  property bool uppercase: true

  signal changed(var selection)

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

  function isOn(key): bool {
    if (root.emptyMeansAll && root.selected.length === 0)
      return true;
    return root.selected.indexOf(key) !== -1;
  }

  function toggle(key): void {
    let list = root.selected.slice();
    // Everything was implicitly on, so turning one off means explicitly
    // listing every other entry rather than leaving the list empty — which
    // would read as "all" again.
    if (root.emptyMeansAll && list.length === 0) {
      list = root.entries.map(e => e.key).filter(k => k !== key);
      root.changed(list);
      return;
    }
    const i = list.indexOf(key);
    if (i !== -1) {
      if (list.length <= root.minSelected)
        return;
      list.splice(i, 1);
    } else {
      list.push(key);
    }
    root.changed(list);
  }

  spacing: 6

  Repeater {
    model: root.entries

    delegate: Item {
      id: chip
      required property var modelData
      readonly property bool on: root.isOn(chip.modelData.key)

      implicitWidth: chipLabel.implicitWidth + 20
      implicitHeight: root.chipHeight

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferIcon
        cutTopRight: true
        cutBottomLeft: true
        fillColor: chip.on ? Color.primaryContainer : (chipHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
        strokeColor: chip.on ? Color.primary : Color.outline
        strokeWidth: Tokens.borderModule
      }

      NText {
        id: chipLabel
        anchors.centerIn: parent
        text: root.uppercase ? String(chip.modelData.label).toUpperCase() : chip.modelData.label
        size: NText.Size.LabelXs
        tracking: true
        color: chip.on ? Color.primaryContainerText : Color.surfaceText
      }

      HoverHandler {
        id: chipHover
        cursorShape: Qt.PointingHandCursor
      }
      TapHandler {
        onTapped: root.toggle(chip.modelData.key)
      }
    }
  }
}
