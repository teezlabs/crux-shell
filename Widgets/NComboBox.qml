import QtQuick
import QtQuick.Controls
import qs.Commons

// Chamfered dropdown. `model` is [{key, label}] (a plain string list is
// accepted too and treated as key === label). The popup is a Controls
// Popup so it escapes any clipping ancestor without needing its own
// window.
Item {
  id: root

  property var model: []
  property string currentKey: ""
  property string placeholder: ""
  // Prefix shown before the value ("QUALITY: 1080p+"), for compact filter
  // rails where a separate label column doesn't fit.
  property string label: ""
  property int textSize: NText.Size.BodySm
  property real popupMaxHeight: 220

  signal selected(string key)

  readonly property bool opened: popup.opened

  function openPopup(): void {
    popup.open();
  }
  function closePopup(): void {
    popup.close();
  }

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

  readonly property string currentLabel: {
    for (const e of root.entries) {
      if (e.key === root.currentKey)
        return e.label;
    }
    return root.placeholder;
  }

  implicitWidth: 180
  implicitHeight: 28
  opacity: enabled ? 1.0 : 0.5

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopRight: true
    cutBottomLeft: true
    fillColor: hover.hovered || popup.opened ? Color.surfaceContainerHigh : Color.surfaceContainer
    strokeColor: popup.opened ? Color.primary : Color.outline
    strokeWidth: Tokens.borderModule
  }

  NText {
    id: valueLabel
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.right: caret.left
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    text: root.label === "" ? root.currentLabel : (root.label + ": " + root.currentLabel)
    size: root.textSize
    color: root.currentKey === "" ? Color.labelText : Color.surfaceText
  }

  // Caret drawn geometrically — no glyph font dependency.
  Canvas {
    id: caret
    anchors.right: parent.right
    anchors.rightMargin: 9
    anchors.verticalCenter: parent.verticalCenter
    width: 9
    height: 6
    readonly property color drawColor: Color.surfaceTextMuted
    onDrawColorChanged: requestPaint()
    onPaint: {
      const ctx = getContext("2d");
      ctx.reset();
      ctx.strokeStyle = drawColor;
      ctx.lineWidth = 1.4;
      ctx.lineCap = "round";
      ctx.lineJoin = "round";
      ctx.beginPath();
      ctx.moveTo(0.5, 1);
      ctx.lineTo(width / 2, height - 1);
      ctx.lineTo(width - 0.5, 1);
      ctx.stroke();
    }
  }

  HoverHandler {
    id: hover
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    enabled: root.enabled
    onTapped: popup.opened ? popup.close() : popup.open()
  }

  Popup {
    id: popup
    y: root.height + 2
    width: root.width
    implicitHeight: Math.min(root.popupMaxHeight, list.contentHeight + 8)
    padding: 4

    background: Chamfer {
      chamferSize: Tokens.chamferIcon
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.surfaceContainerHigh
      strokeColor: Color.outline
      strokeWidth: Tokens.borderModule
    }

    ListView {
      id: list
      anchors.fill: parent
      clip: true
      model: root.entries
      currentIndex: -1
      boundsBehavior: Flickable.StopAtBounds

      delegate: Item {
        id: row
        required property var modelData
        width: list.width
        height: 24

        readonly property bool current: row.modelData.key === root.currentKey

        Rectangle {
          anchors.fill: parent
          color: rowHover.hovered ? Color.surfaceContainer : "transparent"
        }

        // Selection marker, per the spec's left-edge marker convention.
        Rectangle {
          width: Tokens.borderMarker
          height: parent.height
          color: Color.primary
          visible: row.current
        }

        NText {
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.right: parent.right
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          text: row.modelData.label
          size: root.textSize
          color: row.current ? Color.primary : Color.surfaceText
        }

        HoverHandler {
          id: rowHover
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: {
            root.currentKey = row.modelData.key;
            root.selected(row.modelData.key);
            popup.close();
          }
        }
      }
    }
  }
}
