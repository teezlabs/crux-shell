pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Local-folder plugin discovery — no marketplace, no network, no git
// cloning: a plugin is just a directory under ~/.config/crux/plugins/<name>/
// containing manifest.json ({"id": "...", "label": "..."}) and Widget.qml.
// Scanned once at startup (and on demand via rescan()) with a single
// Process rather than one FileView per candidate directory, since the set
// of plugins isn't known ahead of time.
//
// A plugin's Widget.qml is loaded the exact same way a built-in bar widget
// is (see BarWidgetLoader.qml) — `import qs.Commons`/`qs.Modules.Bar.Extras`
// etc still resolve inside it despite living outside the qs.* module tree,
// because those modules were already registered by shell.qml's own static
// imports before any Loader ever touches a plugin file (see the crux
// skill's "dynamically Loader-loaded QML file" gotcha — that only bites a
// module namespace nothing has statically imported yet, which none of
// crux's existing qs.* dirs are).
Singleton {
  id: root

  readonly property string pluginsDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/crux/plugins"

  // {id: {label, dir, error}}
  property var entries: ({})
  readonly property var ids: Object.keys(entries).filter(id => !entries[id].error)
  property string lastScanError: ""

  function hasWidget(id) {
    return entries[id] !== undefined && !entries[id].error;
  }

  function widgetPath(id) {
    return entries[id] ? entries[id].dir + "/Widget.qml" : "";
  }

  function rescan() {
    Quickshell.execDetached(["mkdir", "-p", root.pluginsDir]);
    scanProc.running = true;
  }

  Component.onCompleted: rescan()

  // One-shot python scan: for every immediate subdirectory of pluginsDir
  // with a manifest.json, emit {id, label, dir} (or {dir, error} if the
  // manifest is missing/invalid/missing Widget.qml) as one JSON object per
  // line — cheaper than a Process+FileView per candidate directory for an
  // unknown-ahead-of-time set of plugins.
  Process {
    id: scanProc
    command: ["python3", "-c", "\nimport json, os, sys\nroot = sys.argv[1]\nif not os.path.isdir(root):\n    sys.exit(0)\nfor name in sorted(os.listdir(root)):\n    d = os.path.join(root, name)\n    if not os.path.isdir(d):\n        continue\n    manifest = os.path.join(d, 'manifest.json')\n    widget = os.path.join(d, 'Widget.qml')\n    if not os.path.isfile(manifest):\n        continue\n    try:\n        with open(manifest) as f:\n            m = json.load(f)\n        wid = m['id']\n        label = m.get('label', wid)\n        if not os.path.isfile(widget):\n            print(json.dumps({'id': wid, 'error': 'no Widget.qml', 'dir': d}))\n            continue\n        print(json.dumps({'id': wid, 'label': label, 'dir': d}))\n    except Exception as e:\n        print(json.dumps({'id': name, 'error': str(e), 'dir': d}))\n", root.pluginsDir]
    stdout: StdioCollector {
      id: scanCollector
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: scanErrCollector
      waitForEnd: true
    }
    onExited: function (exitCode) {
      if (exitCode !== 0) {
        root.lastScanError = scanErrCollector.text || ("scan exited " + exitCode);
        return;
      }
      root.lastScanError = "";
      var out = {};
      var lines = scanCollector.text.split("\n").filter(l => l.length > 0);
      for (var i = 0; i < lines.length; i++) {
        try {
          var entry = JSON.parse(lines[i]);
          out[entry.id] = entry;
        } catch (e) {
          // Skip an unparseable line rather than losing every other plugin.
        }
      }
      root.entries = out;
    }
  }
}
