import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Services
import qs.Widgets

// Monitors: drag screens on a map (edges snap to each other), then mode, scale, rotation and on/off per screen.
// Changes are a draft until Apply; Monitors then tries them live and asks to keep them.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  // Editable copy of Monitors.monitors; reset from it whenever nothing is pending.
  property var draft: []
  property string selected: ""
  property bool dirty: false

  function resetDraft() {
    root.draft = Monitors.monitors.map(m => Object.assign({}, m));
    root.dirty = false;
    if (!root.draft.some(m => m.name === root.selected))
      root.selected = root.draft.length > 0 ? root.draft[0].name : "";
  }

  function updateSelected(changes) {
    root.draft = root.draft.map(m => m.name === root.selected ? Object.assign({}, m, changes) : m);
    root.dirty = true;
  }

  readonly property var current: root.draft.find(m => m.name === root.selected) || null

  // "1920x1080@100.00Hz" -> { key, label, width, height, refresh }
  function parseMode(text) {
    const m = /^(\d+)x(\d+)@([\d.]+)/.exec(text);
    if (!m)
      return null;
    const refresh = parseFloat(m[3]);
    return {
      "key": m[1] + "x" + m[2] + "@" + refresh.toFixed(2),
      "label": m[1] + " × " + m[2] + "  ·  " + Math.round(refresh) + " Hz",
      "width": parseInt(m[1]),
      "height": parseInt(m[2]),
      "refresh": refresh
    };
  }

  // Shifts the layout so its top-left corner is at 0,0, as Hyprland expects.
  function normalized(rules) {
    const on = rules.filter(r => !r.disabled);
    if (on.length === 0)
      return rules;
    const minX = Math.min(...on.map(r => r.x));
    const minY = Math.min(...on.map(r => r.y));
    return rules.map(r => Object.assign({}, r, {
          "x": Math.round(r.x - minX),
          "y": Math.round(r.y - minY)
        }));
  }

  Component.onCompleted: resetDraft()
  Connections {
    target: Monitors
    function onMonitorsChanged() {
      if (!root.dirty)
        root.resetDraft();
    }
    // The tried layout is live now; from here the map follows Hyprland again.
    function onTrialActiveChanged() {
      if (Monitors.trialActive)
        root.dirty = false;
    }
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      visible: !Monitors.includeInstalled
      title: "Set up"
      description: "Saved layouts live in ~/.config/hypr/crux-monitors.lua. hyprland.lua needs one line, after its own monitor lines, to load it: " + Monitors.includeLine

      SettingRow {
        label: "Add the line to hyprland.lua"
        description: "A backup goes to hyprland.lua.bak-crux first"
        NButton {
          text: "Add it"
          onClicked: Monitors.installInclude()
        }
      }
    }

    SettingsSection {
      title: "Layout"
      description: "Drag screens to arrange them; edges snap together. Click one to edit it below."

      // ---- The map ----
      Item {
        id: map
        Layout.fillWidth: true
        Layout.preferredHeight: 240

        readonly property var on: root.draft.filter(m => !m.disabled)
        readonly property var bounds: {
          if (map.on.length === 0)
            return {
              "x": 0,
              "y": 0,
              "w": 1,
              "h": 1
            };
          let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
          for (const m of map.on) {
            const s = Monitors.logicalSize(m);
            x0 = Math.min(x0, m.x);
            y0 = Math.min(y0, m.y);
            x1 = Math.max(x1, m.x + s.width);
            y1 = Math.max(y1, m.y + s.height);
          }
          return {
            "x": x0,
            "y": y0,
            "w": x1 - x0,
            "h": y1 - y0
          };
        }
        readonly property real pad: 16
        readonly property real factor: Math.min((width - pad * 2) / bounds.w, (height - pad * 2) / bounds.h)
        readonly property real offX: (width - bounds.w * factor) / 2
        readonly property real offY: (height - bounds.h * factor) / 2

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferModule
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Colors.surfaceContainerLow
          strokeColor: Colors.outlineVariant
          strokeWidth: Tokens.borderModule
        }

        Repeater {
          model: map.on

          delegate: Item {
            id: screenBox
            required property var modelData
            readonly property size logical: Monitors.logicalSize(modelData)
            readonly property bool isSelected: modelData.name === root.selected
            property real dragDx: 0
            property real dragDy: 0
            property real startSceneX: 0
            property real startSceneY: 0

            x: map.offX + (modelData.x - map.bounds.x) * map.factor + dragDx
            y: map.offY + (modelData.y - map.bounds.y) * map.factor + dragDy
            width: logical.width * map.factor
            height: logical.height * map.factor
            z: drag.active ? 2 : (isSelected ? 1 : 0)

            Chamfer {
              anchors.fill: parent
              anchors.margins: 2
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: screenBox.isSelected ? Colors.alpha(Colors.primary, 0.18) : Colors.surfaceContainerHigh
              strokeColor: screenBox.isSelected ? Colors.primary : Colors.outline
              strokeWidth: screenBox.isSelected ? Tokens.borderMarker : Tokens.borderModule
            }
            ColumnLayout {
              anchors.centerIn: parent
              spacing: 2
              NText {
                Layout.alignment: Qt.AlignHCenter
                text: screenBox.modelData.name
                size: NText.Size.BodySm
                font.weight: Font.DemiBold
                color: screenBox.isSelected ? Colors.primary : Colors.surfaceText
              }
              NText {
                Layout.alignment: Qt.AlignHCenter
                text: screenBox.modelData.width + "×" + screenBox.modelData.height + (screenBox.modelData.transform % 2 === 1 ? " · rotated" : "")
                size: NText.Size.LabelXs
                color: Colors.labelText
              }
            }

            HoverHandler {
              cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            }
            TapHandler {
              onTapped: root.selected = screenBox.modelData.name
            }
            // Measured in scene space: the box itself moves while dragged.
            DragHandler {
              id: drag
              target: null
              onActiveChanged: {
                if (active) {
                  root.selected = screenBox.modelData.name;
                  screenBox.startSceneX = centroid.scenePressPosition.x;
                  screenBox.startSceneY = centroid.scenePressPosition.y;
                  return;
                }
                // Back to layout units, then snap to the other screens' edges.
                const me = screenBox.modelData;
                const size = screenBox.logical;
                let nx = me.x + screenBox.dragDx / map.factor;
                let ny = me.y + screenBox.dragDy / map.factor;
                const reach = 80;
                let bestX = null, bestY = null;
                for (const o of map.on) {
                  if (o.name === me.name)
                    continue;
                  const os = Monitors.logicalSize(o);
                  for (const cx of [o.x - size.width, o.x + os.width, o.x, o.x + os.width - size.width]) {
                    if (Math.abs(cx - nx) < reach && (bestX === null || Math.abs(cx - nx) < Math.abs(bestX - nx)))
                      bestX = cx;
                  }
                  for (const cy of [o.y - size.height, o.y + os.height, o.y, o.y + os.height - size.height]) {
                    if (Math.abs(cy - ny) < reach && (bestY === null || Math.abs(cy - ny) < Math.abs(bestY - ny)))
                      bestY = cy;
                  }
                }
                nx = Math.round(bestX !== null ? bestX : nx);
                ny = Math.round(bestY !== null ? bestY : ny);
                screenBox.dragDx = 0;
                screenBox.dragDy = 0;
                root.draft = root.draft.map(m => m.name === me.name ? Object.assign({}, m, {
                      "x": nx,
                      "y": ny
                    }) : m);
                root.dirty = true;
              }
              onCentroidChanged: if (active) {
                screenBox.dragDx = centroid.scenePosition.x - screenBox.startSceneX;
                screenBox.dragDy = centroid.scenePosition.y - screenBox.startSceneY;
              }
            }
          }
        }
      }
    }

    SettingsSection {
      visible: !!root.current
      title: root.current ? root.current.name : ""
      description: root.current ? root.current.description.trim() : ""

      SettingRow {
        label: "On"
        description: "Turning a screen off moves its workspaces to the others"
        NToggle {
          checked: !!root.current && !root.current.disabled
          onToggled: checked => root.updateSelected({
              "disabled": !checked
            })
        }
      }

      SettingRow {
        label: "Resolution"
        NComboBox {
          Layout.preferredWidth: 220
          readonly property var modes: {
            const seen = {};
            const out = [];
            for (const t of (root.current ? root.current.modes : [])) {
              const m = root.parseMode(t);
              if (m && !seen[m.key]) {
                seen[m.key] = true;
                out.push(m);
              }
            }
            return out;
          }
          model: modes
          currentKey: root.current ? root.current.width + "x" + root.current.height + "@" + Number(root.current.refresh).toFixed(2) : ""
          onSelected: key => {
            const m = modes.find(x => x.key === key);
            if (m)
              root.updateSelected({
                "width": m.width,
                "height": m.height,
                "refresh": m.refresh
              });
          }
        }
      }

      SettingRow {
        label: "Scale"
        NSegmented {
          model: ["1", "1.25", "1.5", "1.75", "2"].map(v => ({
                "key": v,
                "label": v + "×"
              }))
          currentKey: root.current ? String(Math.round(root.current.scale * 100) / 100) : ""
          tileWidth: 52
          uppercase: false
          onSelected: key => root.updateSelected({
              "scale": parseFloat(key)
            })
        }
      }

      SettingRow {
        label: "Rotation"
        NSegmented {
          model: [
            {
              "key": "0",
              "label": "0°"
            },
            {
              "key": "1",
              "label": "90°"
            },
            {
              "key": "2",
              "label": "180°"
            },
            {
              "key": "3",
              "label": "270°"
            }
          ]
          currentKey: root.current ? String(root.current.transform % 4) : ""
          tileWidth: 52
          uppercase: false
          onSelected: key => root.updateSelected({
              "transform": parseInt(key)
            })
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Tokens.spaceMd

      NText {
        Layout.fillWidth: true
        visible: text !== ""
        text: Monitors.trialActive ? "Trying it: keep it within " + Monitors.trialRemaining + "s or it goes back" : Monitors.error
        color: Monitors.trialActive ? Colors.primary : Colors.error
        size: NText.Size.BodySm
        wrapMode: Text.WordWrap
      }
      Item {
        Layout.fillWidth: true
        visible: !Monitors.trialActive && Monitors.error === ""
      }
      NButton {
        text: "Discard"
        visible: root.dirty && !Monitors.trialActive
        onClicked: root.resetDraft()
      }
      NButton {
        text: "Apply"
        variant: "accent"
        enabled: root.dirty && !Monitors.trialActive
        onClicked: Monitors.apply(root.normalized(root.draft))
      }
    }
  }
}
