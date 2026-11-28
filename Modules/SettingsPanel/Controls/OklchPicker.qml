import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../../../Commons/Oklch.js" as Oklch

// Colour picker in OKLCH: lightness, chroma and hue sliders over gradient strips, a swatch and a hex field.
// Out-of-gamut picks lose chroma until they fit sRGB (Oklch.toHex).
ColumnLayout {
  id: root

  property string hex: "#808080"
  signal picked(string hex)

  property real l: 0.6
  property real c: 0.1
  property real h: 0
  // Set while a slider drives the colour, so the hex round trip doesn't snap the sliders back.
  property bool _editing: false

  onHexChanged: {
    if (root._editing)
      return;
    const o = Oklch.fromHex(root.hex);
    root.l = o.L;
    root.c = o.C;
    // Greys have no hue; keep the last one so the hue slider doesn't jump to red.
    if (o.C > 0.002)
      root.h = o.H;
  }
  Component.onCompleted: hexChanged()

  function emit() {
    root._editing = true;
    root.picked(Oklch.toHex(root.l, root.c, root.h));
    root._editing = false;
  }

  spacing: Tokens.spaceSm

  RowLayout {
    Layout.fillWidth: true
    spacing: Tokens.spaceMd

    Rectangle {
      Layout.preferredWidth: 44
      Layout.preferredHeight: 44
      color: root.hex
      border.color: Colors.outline
      border.width: Tokens.borderModule
    }
    NTextInput {
      Layout.preferredWidth: 110
      height: 28
      mono: true
      text: root.hex
      onEditingFinished: {
        if (/^#[0-9a-fA-F]{6}$/.test(text.trim()))
          root.picked(text.trim().toLowerCase());
      }
    }
    NText {
      Layout.fillWidth: true
      text: "L " + root.l.toFixed(2) + "   C " + root.c.toFixed(3) + "   H " + Math.round(root.h) + "°"
      size: NText.Size.Caption
      color: Colors.labelText
      font.features: {
        "tnum": 1
      }
    }
  }

  Repeater {
    model: [
      {
        "key": "l",
        "label": "Lightness",
        "from": 0,
        "to": 1
      },
      {
        "key": "c",
        "label": "Chroma",
        "from": 0,
        "to": 0.37
      },
      {
        "key": "h",
        "label": "Hue",
        "from": 0,
        "to": 360
      }
    ]

    delegate: ColumnLayout {
      id: axis
      required property var modelData
      Layout.fillWidth: true
      spacing: 2

      // What this slider sweeps through, with the other two held where they are.
      Canvas {
        id: strip
        Layout.fillWidth: true
        Layout.preferredHeight: 8
        readonly property var deps: [root.l, root.c, root.h, width]
        onDepsChanged: requestPaint()
        onPaint: {
          const ctx = getContext("2d");
          ctx.reset();
          const steps = 48;
          for (let i = 0; i < steps; i++) {
            const t = axis.modelData.from + (axis.modelData.to - axis.modelData.from) * (i + 0.5) / steps;
            const L = axis.modelData.key === "l" ? t : root.l;
            const C = axis.modelData.key === "c" ? t : root.c;
            const H = axis.modelData.key === "h" ? t : root.h;
            ctx.fillStyle = Oklch.toHex(L, C, H);
            ctx.fillRect(Math.floor(width * i / steps), 0, Math.ceil(width / steps) + 1, height);
          }
        }
      }
      NValueSlider {
        Layout.fillWidth: true
        from: axis.modelData.from
        to: axis.modelData.to
        value: root[axis.modelData.key]
        format: v => axis.modelData.label
        onMoved: v => {
          root[axis.modelData.key] = v;
          root.emit();
        }
      }
    }
  }
}
