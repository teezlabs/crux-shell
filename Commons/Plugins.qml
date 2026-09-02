pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Plugin discovery + a git-registry marketplace on top of it. A plugin is
// a directory under ~/.config/crux/plugins/<name>/ with manifest.json +
// Widget.qml, loaded the same way a built-in bar widget is — that part is
// unchanged and still works with zero sources configured. See crux
// skill's notes.md for why qs.* imports still resolve inside it.
//
// Marketplace sources (Settings.data.plugins.sources) are git repos with
// a registry.json at their root: {"plugins": [{"id","label","description",...}]}.
// Installing fetches just that plugin's subdirectory via sparse-checkout
// and copies it into pluginsDir. Fetching only ever shell-interpolates
// the source's own url (something the user typed in themselves, same
// trust level as any other configured URL) — every value that comes back
// *from* a registry (plugin id, in particular) is passed as its own argv
// entry to git/mkdir/cp, never built into a shell string, since a
// malicious or compromised source could otherwise put shell metacharacters
// in a plugin id and have them executed.
Singleton {
  id: root

  readonly property string pluginsDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/crux/plugins"
  readonly property string _tmpBase: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/crux-plugin-fetch"

  // {id: {label, dir, error}}
  property var entries: ({})
  readonly property var ids: Object.keys(entries).filter(id => !entries[id].error)
  property string lastScanError: ""

  // Marketplace state
  property var availablePlugins: [] // [{id, label, description, source: {url,name}}]
  property var fetchErrors: ({}) // {sourceUrl: errorText}
  property bool fetching: false
  property var installing: ({}) // {pluginId: true}
  property string lastInstallError: ""

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

  // Only [a-zA-Z0-9_-] survives, and the result must be non-empty — a
  // remote registry's plugin id becomes a real local directory name
  // (pluginsDir/<id>), so this is the one hard guard against a malicious
  // id trying to path-traverse (e.g. "../../..") out of pluginsDir.
  function _safeId(id) {
    var cleaned = String(id || "").replace(/[^a-zA-Z0-9_-]/g, "");
    return cleaned;
  }

  Component.onCompleted: rescan()

  // One-shot python scan: emits {id, label, dir} (or {dir, error}) per
  // qualifying subdirectory, one JSON object per line.
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

  // ---- Marketplace: fetch each enabled source's registry.json ----

  function refreshAvailable() {
    var sources = (Settings.data.plugins.sources || []).filter(s => s.enabled !== false && s.url);
    root.availablePlugins = [];
    root.fetchErrors = {};
    if (sources.length === 0) {
      root.fetching = false;
      return;
    }
    root.fetching = true;
    var remaining = sources.length;
    for (var i = 0; i < sources.length; i++)
      _fetchOne(sources[i], function () {
        remaining--;
        if (remaining <= 0)
          root.fetching = false;
      });
  }

  function _fetchOne(source, onDone) {
    // Only source.url (something the user typed into Settings themselves)
    // is interpolated into this shell string — nothing from the fetched
    // registry itself.
    var tmp = root._tmpBase + "-" + Date.now() + "-" + Math.floor(Math.random() * 100000);
    var cmd = "mkdir -p " + JSON.stringify(tmp) + " && GIT_TERMINAL_PROMPT=0 git clone --filter=blob:none --sparse --depth=1 --quiet " + JSON.stringify(source.url) + " " + JSON.stringify(tmp) + " 2>/dev/null && git -C " + JSON.stringify(tmp) + " sparse-checkout set --no-cone /registry.json 2>/dev/null && cat " + JSON.stringify(tmp + "/registry.json") + "; rm -rf " + JSON.stringify(tmp);
    var proc = Qt.createQmlObject('import Quickshell.Io; Process { stdout: StdioCollector { waitForEnd: true } }', root, "PluginFetch_" + tmp);
    proc.command = ["sh", "-c", cmd];
    proc.exited.connect(function (exitCode) {
      var text = proc.stdout.text;
      try {
        var registry = JSON.parse(text);
        if (registry && Array.isArray(registry.plugins)) {
          for (var i = 0; i < registry.plugins.length; i++) {
            var p = registry.plugins[i];
            p.source = {
              "url": source.url,
              "name": source.name || source.url
            };
            p.installed = root.hasWidget(root._safeId(p.id));
            root.availablePlugins.push(p);
          }
          root.availablePluginsChanged();
        }
      } catch (e) {
        root.fetchErrors[source.url] = "Couldn't read registry.json (" + (exitCode !== 0 ? "exit " + exitCode : "bad JSON") + ")";
        root.fetchErrorsChanged();
      }
      proc.destroy();
      onDone();
    });
    proc.running = true;
  }

  // ---- Marketplace: install/uninstall one plugin ----

  function installPlugin(entry) {
    var safeId = root._safeId(entry.id);
    if (!safeId) {
      root.lastInstallError = "Plugin id rejected (empty after sanitizing): " + entry.id;
      return;
    }
    var busy = Object.assign({}, root.installing);
    busy[entry.id] = true;
    root.installing = busy;
    root.lastInstallError = "";

    var tmp = root._tmpBase + "-install-" + Date.now();
    Quickshell.execDetached(["mkdir", "-p", tmp]);

    var clone = Qt.createQmlObject('import Quickshell.Io; Process {}', root, "PluginClone_" + tmp);
    // source.url is user-configured; entry.id (registry-supplied) never
    // enters a shell string anywhere in this chain, only argv positions.
    clone.command = ["git", "clone", "--filter=blob:none", "--sparse", "--depth=1", "--quiet", entry.source.url, tmp];
    clone.exited.connect(function (exitCode) {
      if (exitCode !== 0) {
        root._installFailed(entry.id, "git clone failed (exit " + exitCode + ")");
        clone.destroy();
        return;
      }
      var checkout = Qt.createQmlObject('import Quickshell.Io; Process {}', root, "PluginCheckout_" + tmp);
      checkout.command = ["git", "-C", tmp, "sparse-checkout", "set", "--no-cone", entry.id];
      checkout.exited.connect(function (checkoutExit) {
        if (checkoutExit !== 0) {
          root._installFailed(entry.id, "sparse-checkout failed (exit " + checkoutExit + ")");
          checkout.destroy();
          clone.destroy();
          return;
        }
        var destDir = root.pluginsDir + "/" + safeId;
        Quickshell.execDetached(["mkdir", "-p", root.pluginsDir]);
        var copy = Qt.createQmlObject('import Quickshell.Io; Process {}', root, "PluginCopy_" + tmp);
        copy.command = ["cp", "-r", tmp + "/" + entry.id, destDir];
        copy.exited.connect(function (copyExit) {
          Quickshell.execDetached(["rm", "-rf", tmp]);
          if (copyExit !== 0) {
            root._installFailed(entry.id, "copy into pluginsDir failed (exit " + copyExit + ")");
          } else {
            var busy2 = Object.assign({}, root.installing);
            delete busy2[entry.id];
            root.installing = busy2;
            root.rescan();
            root.refreshAvailable();
          }
          copy.destroy();
          checkout.destroy();
          clone.destroy();
        });
        copy.running = true;
      });
      checkout.running = true;
    });
    clone.running = true;
  }

  function _installFailed(pluginId, message) {
    root.lastInstallError = message;
    var busy = Object.assign({}, root.installing);
    delete busy[pluginId];
    root.installing = busy;
  }

  function uninstallPlugin(id) {
    var safeId = root._safeId(id);
    if (!safeId)
      return;
    Quickshell.execDetached(["rm", "-rf", root.pluginsDir + "/" + safeId]);
    rescanAfterUninstall.restart();
  }

  Timer {
    id: rescanAfterUninstall
    interval: 300
    onTriggered: {
      root.rescan();
      root.refreshAvailable();
    }
  }
}
