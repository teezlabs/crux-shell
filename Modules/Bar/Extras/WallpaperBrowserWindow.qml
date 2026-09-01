import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Modules.Bar.Extras

// Wallpaper browser: centered floating card (not the spec's fullscreen mockup). Local library only. See crux skill's notes.md.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  function toggle() {
    visible = !visible;
  }
  function open() {
    visible = true;
  }
  function close() {
    visible = false;
  }

  visible: false
  color: "transparent"
  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-wallpaper-browser"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  IpcHandler {
    target: "wallpaperBrowser_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle(): void {
      root.toggle();
    }
    function open(): void {
      root.open();
    }
    function close(): void {
      root.close();
    }
  }
  // Claimed only by the instance on the currently-focused monitor, for a
  // keybind that doesn't know/care which screen it's on.
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "wallpaperBrowser"
    function toggle(): void {
      root.toggle();
    }
    function open(): void {
      root.open();
    }
    function close(): void {
      root.close();
    }
  }

  // Compact "LABEL: value ▾" dropdown, opens a Popup list on click — used
  // for Wallhaven's quality/ratio filters, which have too many options for
  // pills to stay readable in the rail's width.
  component FilterDropdown: Item {
    id: dd
    property string label: ""
    property var model: [] // [{key, label}]
    property string value: ""
    signal selected(string key)

    implicitHeight: 24
    readonly property var _current: {
      for (var i = 0; i < model.length; i++)
        if (model[i].key === value)
          return model[i];
      return model.length > 0 ? model[0] : ({
          "label": ""
        });
    }

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferIcon
      cutTopRight: true
      cutBottomLeft: true
      fillColor: ddMouse.containsMouse ? Color.surfaceContainerHigh : Color.surfaceContainer
      strokeColor: Color.outline
      strokeWidth: Tokens.borderModule
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 6
      spacing: 4
      Text {
        Layout.fillWidth: true
        text: dd.label + ": " + dd._current.label
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
        elide: Text.ElideRight
      }
      Text {
        text: ddPopup.visible ? "▲" : "▼"
        color: Color.labelText
        font.pixelSize: 7
      }
    }

    MouseArea {
      id: ddMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: ddPopup.visible = !ddPopup.visible
    }

    Popup {
      id: ddPopup
      y: dd.height + 2
      width: dd.width
      padding: 4
      closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
      background: Rectangle {
        color: Color.surface
        border.width: 1
        border.color: Color.outline
      }
      contentItem: Column {
        spacing: 1
        Repeater {
          model: dd.model
          delegate: Rectangle {
            id: optRow
            required property var modelData
            width: ddPopup.width - 8
            height: 22
            color: modelData.key === dd.value ? Color.alpha(Color.primary, 0.2) : (optMouse.containsMouse ? Color.surfaceContainerHigh : "transparent")
            Text {
              anchors.centerIn: parent
              text: optRow.modelData.label
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.captionSize
            }
            MouseArea {
              id: optMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                dd.selected(optRow.modelData.key);
                ddPopup.visible = false;
              }
            }
          }
        }
      }
    }
  }

  // "local" | "wallhaven"
  property string sourceMode: "local"

  // ---- Local library scan ----
  property var files: [] // [{path, name, ext, mtime}]
  property string searchText: ""
  property string sortMode: "name" // "name" | "date"
  readonly property var localFiltered: {
    var q = root.searchText.toLowerCase();
    var out = q === "" ? root.files : root.files.filter(f => f.name.toLowerCase().indexOf(q) !== -1);
    var sorted = out.slice();
    if (root.sortMode === "date")
      sorted.sort((a, b) => b.mtime - a.mtime);
    else
      sorted.sort((a, b) => a.name.localeCompare(b.name));
    return sorted;
  }
  readonly property var filteredFiles: root.sourceMode === "wallhaven" ? root.whResults : root.localFiltered

  function rescan() {
    scanProc.command = ["sh", "-c", "find " + JSON.stringify(Settings.data.wallpaper.directory) + " -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' \\) -printf '%T@|%p\\n'"];
    scanProc.running = true;
  }

  Process {
    id: scanProc
    stdout: StdioCollector {
      id: scanCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var lines = scanCollector.text.split("\n").filter(l => l.length > 0);
      var out = [];
      for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].split("|");
        if (parts.length < 2)
          continue;
        var mtime = parseFloat(parts[0]);
        var path = parts.slice(1).join("|");
        var name = path.substring(path.lastIndexOf("/") + 1);
        var ext = name.substring(name.lastIndexOf(".") + 1).toLowerCase();
        out.push({
          "path": path,
          "name": name,
          "ext": ext,
          "mtime": mtime
        });
      }
      root.files = out;
    }
  }

  // ---- Wallhaven search (wallhaven.cc public API — no key required for
  // SFW toplist search) ----
  readonly property string _userAgent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  property var whResults: [] // [{id, path (full-res url), thumb, name, ext, isRemote:true}]
  property bool whLoading: false
  property string whError: ""
  property string whSorting: "toplist" // toplist | date_added | views | favorites
  property int whPage: 1
  property int whLastPage: 1
  property bool downloading: false

  readonly property string _whPurity: (Settings.data.wallpaper.wallhavenSfw ? "1" : "0") + (Settings.data.wallpaper.wallhavenSketchy ? "1" : "0") + (Settings.data.wallpaper.wallhavenNsfw ? "1" : "0")

  function _whBuildUrl(page) {
    var url = "https://wallhaven.cc/api/v1/search?categories=111&purity=" + root._whPurity + "&";
    if (root.searchText)
      url += "q=" + encodeURIComponent(root.searchText) + "&";
    url += "sorting=" + root.whSorting + "&order=desc&";
    if (root.whSorting === "toplist")
      url += "topRange=1M&";
    if (Settings.data.wallpaper.wallhavenApiKey)
      url += "apikey=" + encodeURIComponent(Settings.data.wallpaper.wallhavenApiKey) + "&";
    if (Settings.data.wallpaper.wallhavenAtLeast)
      url += "atleast=" + Settings.data.wallpaper.wallhavenAtLeast + "&";
    if (Settings.data.wallpaper.wallhavenRatio)
      url += "ratios=" + Settings.data.wallpaper.wallhavenRatio + "&";
    url += "page=" + page;
    return url;
  }

  function whSearch(page, append) {
    if (root.whLoading)
      return;
    root.whLoading = true;
    root.whError = "";
    root.whPage = page || 1;
    whSearchProc.append = !!append;
    whSearchProc.command = ["curl", "-fsSL", "-A", root._userAgent, root._whBuildUrl(root.whPage)];
    whSearchProc.running = true;
  }

  Process {
    id: whSearchProc
    property bool append: false
    stdout: StdioCollector {
      id: whSearchCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      root.whLoading = false;
      if (exitCode !== 0) {
        root.whError = "Network error (curl exit " + exitCode + ")";
        return;
      }
      try {
        var json = JSON.parse(whSearchCollector.text);
        if (json.error) {
          root.whError = json.error;
          return;
        }
        var items = (json.data || []).map(item => {
          var ext = item.path.split(".").pop().split("?")[0].toLowerCase();
          return {
            "id": item.id,
            "path": item.path,
            "thumb": item.thumbs ? item.thumbs.large : item.path,
            "name": "wallhaven-" + item.id + "." + ext,
            "ext": ext,
            "isRemote": true
          };
        });
        root.whResults = whSearchProc.append ? root.whResults.concat(items) : items;
        root.whLastPage = json.meta && json.meta.last_page ? json.meta.last_page : 1;
        root.selectedIndex = 0;
      } catch (e) {
        root.whError = "Parse error: " + e.message;
      }
    }
  }

  property string _downloadDest: ""
  property bool _pendingWithTheme: false

  function _downloadAndApply(item, withTheme) {
    var ext = item.path.split(".").pop().split("?")[0].toLowerCase();
    if (["jpg", "jpeg", "png", "webp", "gif", "bmp"].indexOf(ext) === -1)
      ext = "jpg";
    root._downloadDest = Settings.data.wallpaper.directory + "/wallhaven-" + item.id + "." + ext;
    root._pendingWithTheme = withTheme;
    root.downloading = true;
    whDownloadProc.command = ["curl", "-fsSL", "-A", root._userAgent, "-o", root._downloadDest, item.path];
    whDownloadProc.running = true;
  }

  Process {
    id: whDownloadProc
    onExited: exitCode => {
      root.downloading = false;
      if (exitCode !== 0) {
        root.whError = "Download failed";
        return;
      }
      Settings.setWallpaperForScreen(root.targetMonitor, root._downloadDest);
      if (root._pendingWithTheme && Settings.data.wallpaper.autoTheme)
        Matugen.generateFrom(root._downloadDest);
    }
  }

  property int selectedIndex: 0
  // Keeps keyboard nav from moving the highlight below/above the visible
  // viewport with no way to see where it went — cell height (88) + spacing
  // (8) matches the delegate's own Layout.preferredHeight below.
  onSelectedIndexChanged: {
    var row = Math.floor(selectedIndex / _columns);
    var cellH = 96;
    var top = row * cellH;
    var bottom = top + cellH;
    if (top < gridFlick.contentY)
      gridFlick.contentY = top;
    else if (bottom > gridFlick.contentY + gridFlick.height)
      gridFlick.contentY = bottom - gridFlick.height;
  }
  readonly property var selectedFile: root.filteredFiles.length > 0 ? root.filteredFiles[Math.min(root.selectedIndex, root.filteredFiles.length - 1)] : null
  readonly property bool selectedIsVideo: root.selectedFile && !root.selectedFile.isRemote ? (root.selectedFile.ext === "mp4" || root.selectedFile.ext === "webm") : false

  // "" = apply to every monitor; otherwise a specific screen name.
  property string targetMonitor: ""

  function applyWallpaper(withTheme) {
    if (!root.selectedFile || root.downloading)
      return;
    if (root.selectedFile.isRemote) {
      root._downloadAndApply(root.selectedFile, withTheme);
      return;
    }
    Settings.setWallpaperForScreen(root.targetMonitor, root.selectedFile.path);
    if (withTheme && Settings.data.wallpaper.autoTheme)
      Matugen.generateFrom(root.selectedFile.path);
  }

  // Arm-then-confirm (same convention as the session menu's destructive
  // actions) — the delete button reads "DELETE" once, "CONFIRM DELETE?" for
  // a few seconds after, and only actually removes the file on that second
  // click. Armed state is keyed by path so switching selection disarms it.
  property string armedDeletePath: ""

  Timer {
    id: deleteArmTimer
    interval: 3000
    onTriggered: root.armedDeletePath = ""
  }

  function requestDelete() {
    if (!root.selectedFile || root.selectedFile.isRemote)
      return;
    if (root.armedDeletePath !== root.selectedFile.path) {
      root.armedDeletePath = root.selectedFile.path;
      deleteArmTimer.restart();
      return;
    }
    deleteArmTimer.stop();
    root.armedDeletePath = "";
    deleteProc.command = ["rm", "-f", "--", root.selectedFile.path];
    deleteProc.running = true;
  }

  Process {
    id: deleteProc
    onExited: exitCode => root.rescan()
  }

  onSelectedFileChanged: root.armedDeletePath = ""

  onVisibleChanged: if (visible) {
    root.rescan();
    root.selectedIndex = 0;
  }

  // Don't steal focus into searchInput on open, or arrow/Enter/R shortcuts below (gated on !activeFocus) go dead.
  // Column count from the Flickable's real width, not hand-computed from card.width.
  readonly property int _columns: Math.max(1, Math.floor(gridFlick.width / 150))

  function _moveSelection(dx, dy) {
    if (root.filteredFiles.length === 0)
      return;
    var idx = root.selectedIndex + dx + dy * root._columns;
    idx = Math.max(0, Math.min(root.filteredFiles.length - 1, idx));
    root.selectedIndex = idx;
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.close()
  }
  Shortcut {
    sequence: "Left"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: root._moveSelection(-1, 0)
  }
  Shortcut {
    sequence: "Right"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: root._moveSelection(1, 0)
  }
  Shortcut {
    sequence: "Up"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: root._moveSelection(0, -1)
  }
  Shortcut {
    sequence: "Down"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: root._moveSelection(0, 1)
  }
  Shortcut {
    sequence: "Return"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: root.applyWallpaper(true)
  }
  Shortcut {
    sequence: "Shift+Return"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: root.applyWallpaper(false)
  }
  Shortcut {
    sequence: "/"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: searchInput.forceActiveFocus()
  }
  Shortcut {
    sequence: "R"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: if (root.filteredFiles.length > 0)
      root.selectedIndex = Math.floor(Math.random() * root.filteredFiles.length)
  }
  Shortcut {
    sequence: "Delete"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: root.requestDelete()
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Item {
    id: card
    anchors.centerIn: parent
    // Clamped to the actual screen size (minus a margin) — a portrait/
    // narrow monitor is smaller than the 1200x720 default, and nothing
    // was capping it, so the card overflowed straight off the edges there.
    width: Math.min(1200, root.width - 40)
    height: Math.min(720, root.height - 40)

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 12

    // ---- Header ----
    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      Rectangle {
        width: 3
        height: 20
        color: Color.primary
      }
      Text {
        text: "WALLPAPER BROWSER"
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodyLgSize
        font.weight: Font.DemiBold
        font.letterSpacing: 1
      }
      Item {
        Layout.fillWidth: true
      }
      Text {
        text: root.sourceMode === "wallhaven" ? (root.whLoading ? "SEARCHING…" : root.whResults.length + " RESULTS" + (root.whError ? " · " + root.whError : "")) : root.filteredFiles.length + " OF " + root.files.length
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 16

      // ---- Left rail: search / sort / directory ----
      ColumnLayout {
        Layout.preferredWidth: 220
        Layout.minimumWidth: 220
        Layout.maximumWidth: 220
        Layout.fillHeight: true
        spacing: 14

        RowLayout {
          Layout.fillWidth: true
          spacing: 4
          Repeater {
            model: [
              {
                "key": "local",
                "label": "LOCAL"
              },
              {
                "key": "wallhaven",
                "label": "WALLHAVEN"
              }
            ]
            delegate: Item {
              id: srcPill
              required property var modelData
              readonly property bool selected: root.sourceMode === modelData.key
              Layout.fillWidth: true
              height: 26
              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: srcPill.selected ? Color.primaryContainer : Color.surfaceContainer
                strokeColor: srcPill.selected ? Color.primary : Color.outline
                strokeWidth: Tokens.borderModule
              }
              Text {
                anchors.centerIn: parent
                text: srcPill.modelData.label
                color: srcPill.selected ? Color.primaryContainerText : Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: 8
                font.weight: Font.DemiBold
              }
              HoverHandler {
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: {
                  root.sourceMode = srcPill.modelData.key;
                  root.selectedIndex = 0;
                  if (root.sourceMode === "wallhaven" && root.whResults.length === 0)
                    root.whSearch(1, false);
                }
              }
            }
          }
        }

        Item {
          Layout.fillWidth: true
          height: 30

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Color.surface
            strokeColor: searchInput.activeFocus ? Color.primary : Color.outline
            strokeWidth: Tokens.borderModule
          }

          TextInput {
            id: searchInput
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: Text.AlignVCenter
            color: Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
            selectByMouse: true
            onTextChanged: {
              root.searchText = text;
              if (root.sourceMode === "local")
                root.selectedIndex = 0;
            }
            onAccepted: if (root.sourceMode === "wallhaven")
              root.whSearch(1, false)

            Text {
              anchors.centerIn: parent
              visible: parent.text === "" && !parent.activeFocus
              text: root.sourceMode === "wallhaven" ? "/ SEARCH WALLHAVEN ⏎" : "/ SEARCH"
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          Text {
            text: "SORT"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
          RowLayout {
            spacing: 4
            Repeater {
              model: root.sourceMode === "wallhaven" ? [
                {
                  "key": "toplist",
                  "label": "Top"
                },
                {
                  "key": "date_added",
                  "label": "Latest"
                },
                {
                  "key": "views",
                  "label": "Views"
                },
                {
                  "key": "favorites",
                  "label": "Faves"
                }
              ] : [
                {
                  "key": "name",
                  "label": "Name"
                },
                {
                  "key": "date",
                  "label": "Recent"
                }
              ]
              delegate: Item {
                id: sortPill
                required property var modelData
                readonly property bool selected: root.sourceMode === "wallhaven" ? root.whSorting === modelData.key : root.sortMode === modelData.key
                width: sortLabel.implicitWidth + 18
                height: 24
                Chamfer {
                  anchors.fill: parent
                  chamferSize: Tokens.chamferIcon
                  cutTopRight: true
                  cutBottomLeft: true
                  fillColor: sortPill.selected ? Color.primaryContainer : Color.surfaceContainer
                  strokeColor: sortPill.selected ? Color.primary : Color.outline
                  strokeWidth: Tokens.borderModule
                }
                Text {
                  id: sortLabel
                  anchors.centerIn: parent
                  text: sortPill.modelData.label
                  color: sortPill.selected ? Color.primaryContainerText : Color.surfaceText
                  font.family: Tokens.fontFamily
                  font.pixelSize: Tokens.labelXsSize
                }
                HoverHandler {
                  cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                  onTapped: {
                    if (root.sourceMode === "wallhaven") {
                      root.whSorting = sortPill.modelData.key;
                      root.whSearch(1, false);
                    } else {
                      root.sortMode = sortPill.modelData.key;
                    }
                  }
                }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          visible: root.sourceMode === "wallhaven"
          Text {
            text: "PURITY"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
          RowLayout {
            spacing: 4
            Repeater {
              model: [
                {
                  "key": "wallhavenSfw",
                  "label": "SFW"
                },
                {
                  "key": "wallhavenSketchy",
                  "label": "Sketchy"
                },
                {
                  "key": "wallhavenNsfw",
                  "label": "NSFW"
                }
              ]
              delegate: Item {
                id: purityPill
                required property var modelData
                readonly property bool selected: Settings.data.wallpaper[modelData.key]
                width: purityLabel.implicitWidth + 18
                height: 24
                Chamfer {
                  anchors.fill: parent
                  chamferSize: Tokens.chamferIcon
                  cutTopRight: true
                  cutBottomLeft: true
                  fillColor: purityPill.selected ? Color.primaryContainer : Color.surfaceContainer
                  strokeColor: purityPill.selected ? Color.primary : Color.outline
                  strokeWidth: Tokens.borderModule
                }
                Text {
                  id: purityLabel
                  anchors.centerIn: parent
                  text: purityPill.modelData.label
                  color: purityPill.selected ? Color.primaryContainerText : Color.surfaceText
                  font.family: Tokens.fontFamily
                  font.pixelSize: Tokens.labelXsSize
                }
                HoverHandler {
                  cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                  onTapped: {
                    Settings.data.wallpaper[purityPill.modelData.key] = !purityPill.selected;
                    root.whSearch(1, false);
                  }
                }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          visible: root.sourceMode === "wallhaven"
          Text {
            text: "QUALITY / RATIO"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
          FilterDropdown {
            Layout.fillWidth: true
            label: "QUALITY"
            value: Settings.data.wallpaper.wallhavenAtLeast
            model: [
              {
                "key": "",
                "label": "Any"
              },
              {
                "key": "1920x1080",
                "label": "1080p+"
              },
              {
                "key": "2560x1440",
                "label": "1440p+"
              },
              {
                "key": "3840x2160",
                "label": "4K+"
              }
            ]
            onSelected: key => {
              Settings.data.wallpaper.wallhavenAtLeast = key;
              root.whSearch(1, false);
            }
          }
          FilterDropdown {
            Layout.fillWidth: true
            label: "RATIO"
            value: Settings.data.wallpaper.wallhavenRatio
            model: [
              {
                "key": "",
                "label": "Any"
              },
              {
                "key": "16x9",
                "label": "16:9"
              },
              {
                "key": "21x9",
                "label": "21:9"
              },
              {
                "key": "9x16",
                "label": "Portrait"
              }
            ]
            onSelected: key => {
              Settings.data.wallpaper.wallhavenRatio = key;
              root.whSearch(1, false);
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          Text {
            text: "DIRECTORY"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
          Item {
            Layout.fillWidth: true
            height: 26
            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Color.surface
              strokeColor: dirInput.activeFocus ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }
            TextInput {
              id: dirInput
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              verticalAlignment: Text.AlignVCenter
              text: Settings.data.wallpaper.directory
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.captionSize
              selectByMouse: true
              onEditingFinished: {
                Settings.data.wallpaper.directory = text;
                root.rescan();
              }
            }
          }
        }

        Item {
          Layout.fillHeight: true
        }

        Text {
          text: "← → ↑ ↓ MOVE\n⏎ APPLY + THEME\n⇧⏎ WALLPAPER ONLY\n/ SEARCH  R RANDOM\nESC CLOSE"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          lineHeight: 1.6
        }
      }

      // ---- Grid ----
      Flickable {
        id: gridFlick
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: width
        contentHeight: grid.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
          policy: gridFlick.contentHeight > gridFlick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        }

        GridLayout {
          id: grid
          width: gridFlick.width
          height: implicitHeight
          columns: root._columns
          rowSpacing: 8
          columnSpacing: 8

          Repeater {
            model: root.filteredFiles
            delegate: Item {
              id: thumb
              required property var modelData
              required property int index
              readonly property bool isSelected: index === root.selectedIndex
              readonly property bool isVideo: !modelData.isRemote && (modelData.ext === "mp4" || modelData.ext === "webm")
              readonly property bool isRemote: !!modelData.isRemote
              Layout.preferredWidth: 140
              Layout.preferredHeight: 88

              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: Color.surfaceContainer
                strokeColor: thumb.isSelected ? Color.primary : Color.outline
                strokeWidth: thumb.isSelected ? 2 : Tokens.borderModule
              }

              Image {
                id: thumbImage
                anchors.fill: parent
                anchors.margins: thumb.isSelected ? 2 : 1
                source: thumb.isVideo ? "" : thumb.isRemote ? thumb.modelData.thumb : "file://" + thumb.modelData.path
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: false
              }

              // Chamfer.qml only draws the border/fill behind the image —
              // clip the image itself to the same cut-corner shape via
              // MultiEffect's mask, or it just sits as a plain rectangle
              // poking out past the cut corners.
              Chamfer {
                id: thumbMask
                anchors.fill: thumbImage
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: "white"
                visible: false
                layer.enabled: true
              }

              MultiEffect {
                anchors.fill: thumbImage
                source: thumbImage
                maskEnabled: true
                maskSource: thumbMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
              }

              // Type badge, top-left corner.
              Item {
                x: 3
                y: 3
                width: badgeLabel.implicitWidth + 8
                height: 15
                Rectangle {
                  anchors.fill: parent
                  color: thumb.isVideo ? Color.alpha(Color.tertiary, 0.85) : thumb.isRemote ? Color.alpha(Color.primary, 0.85) : Color.alpha(Color.surface, 0.75)
                }
                Text {
                  id: badgeLabel
                  anchors.centerIn: parent
                  text: thumb.isVideo ? "VID" : thumb.isRemote ? "WEB" : "IMG"
                  color: (thumb.isVideo || thumb.isRemote) ? Color.mOnPrimary : Color.labelText
                  font.family: Tokens.fontFamily
                  font.pixelSize: 8
                  font.weight: Font.DemiBold
                }
              }

              HoverHandler {
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: root.selectedIndex = thumb.index
                onDoubleTapped: root.applyWallpaper(true)
              }
            }
          }

          Item {
            visible: root.sourceMode === "wallhaven" && root.whPage < root.whLastPage
            Layout.columnSpan: root._columns
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            Layout.topMargin: 4

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: loadMoreHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
              strokeColor: Color.outline
              strokeWidth: Tokens.borderModule
            }
            Text {
              anchors.centerIn: parent
              text: root.whLoading ? "LOADING…" : "LOAD MORE"
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
            }
            HoverHandler {
              id: loadMoreHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: root.whSearch(root.whPage + 1, true)
            }
          }
        }
      }

      // ---- Right detail panel ----
      ColumnLayout {
        Layout.preferredWidth: 300
        Layout.minimumWidth: 300
        Layout.maximumWidth: 300
        Layout.fillHeight: true
        spacing: 12

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: 170

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferPanel
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Color.surfaceContainer
            strokeColor: Color.outline
            strokeWidth: Tokens.borderModule
          }

          Image {
            id: previewImage
            anchors.fill: parent
            anchors.margins: 2
            visible: false
            source: {
              if (!root.selectedFile || root.selectedIsVideo)
                return "";
              return root.selectedFile.isRemote ? root.selectedFile.thumb : "file://" + root.selectedFile.path;
            }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true

            readonly property int imgW: sourceSize.width
            readonly property int imgH: sourceSize.height
          }

          Chamfer {
            id: previewMask
            anchors.fill: previewImage
            chamferSize: Tokens.chamferPanel
            cutTopRight: true
            cutBottomLeft: true
            fillColor: "white"
            visible: false
            layer.enabled: true
          }

          MultiEffect {
            anchors.fill: previewImage
            visible: root.selectedFile && !root.selectedIsVideo
            source: previewImage
            maskEnabled: true
            maskSource: previewMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
          }

          Text {
            visible: !root.selectedFile
            anchors.centerIn: parent
            text: "NO SELECTION"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2
          visible: root.selectedFile !== null
          Text {
            text: root.selectedFile ? root.selectedFile.name : ""
            color: Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
            elide: Text.ElideMiddle
            Layout.fillWidth: true
          }
          Text {
            text: Settings.data.wallpaper.directory
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.captionSize
            elide: Text.ElideMiddle
            Layout.fillWidth: true
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Color.surfaceContainerHigh
        }

        // ---- Monitor targeting ----
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          Text {
            text: "TARGET"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
          Flow {
            Layout.fillWidth: true
            spacing: 4

            Item {
              id: allPill
              readonly property bool selected: root.targetMonitor === ""
              width: allLabel.implicitWidth + 18
              height: 24
              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: allPill.selected ? Color.primaryContainer : Color.surfaceContainer
                strokeColor: allPill.selected ? Color.primary : Color.outline
                strokeWidth: Tokens.borderModule
              }
              Text {
                id: allLabel
                anchors.centerIn: parent
                text: "ALL"
                color: allPill.selected ? Color.primaryContainerText : Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.labelXsSize
              }
              HoverHandler {
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: root.targetMonitor = ""
              }
            }

            Repeater {
              model: Quickshell.screens
              delegate: Item {
                id: monPill
                required property var modelData
                readonly property bool selected: root.targetMonitor === modelData.name
                width: monLabel.implicitWidth + 18
                height: 24
                Chamfer {
                  anchors.fill: parent
                  chamferSize: Tokens.chamferIcon
                  cutTopRight: true
                  cutBottomLeft: true
                  fillColor: monPill.selected ? Color.primaryContainer : Color.surfaceContainer
                  strokeColor: monPill.selected ? Color.primary : Color.outline
                  strokeWidth: Tokens.borderModule
                }
                Text {
                  id: monLabel
                  anchors.centerIn: parent
                  text: monPill.modelData.name + (monPill.modelData === Quickshell.screens[0] ? " ★" : "")
                  color: monPill.selected ? Color.primaryContainerText : Color.surfaceText
                  font.family: Tokens.fontFamily
                  font.pixelSize: Tokens.labelXsSize
                }
                HoverHandler {
                  cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                  onTapped: root.targetMonitor = monPill.modelData.name
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Color.surfaceContainerHigh
        }

        // ---- Matugen scheme + templates ----
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          Text {
            text: "SCHEME"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
          Flow {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
              model: ["scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-tonal-spot", "scheme-vibrant"]
              delegate: Item {
                id: schemePill
                required property string modelData
                readonly property bool selected: Settings.data.wallpaper.matugenScheme === modelData
                readonly property string label: modelData.replace("scheme-", "")
                width: schemeLabel.implicitWidth + 14
                height: 22
                Chamfer {
                  anchors.fill: parent
                  chamferSize: Tokens.chamferIcon
                  cutTopRight: true
                  cutBottomLeft: true
                  fillColor: schemePill.selected ? Color.primaryContainer : Color.surfaceContainer
                  strokeColor: schemePill.selected ? Color.primary : Color.outline
                  strokeWidth: Tokens.borderModule
                }
                Text {
                  id: schemeLabel
                  anchors.centerIn: parent
                  text: schemePill.label
                  color: schemePill.selected ? Color.primaryContainerText : Color.surfaceText
                  font.family: Tokens.fontFamily
                  font.pixelSize: 8
                }
                HoverHandler {
                  cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                  onTapped: {
                    Settings.data.wallpaper.matugenScheme = schemePill.modelData;
                    // Live preview — matugen needs a real local file, so a
                    // Wallhaven result not yet downloaded can't regenerate
                    // until it's actually applied.
                    if (root.selectedFile && !root.selectedFile.isRemote)
                      Matugen.generateFrom(root.selectedFile.path);
                  }
                }
              }
            }
          }
          Text {
            readonly property int _enabledCount: {
              var t = Settings.data.wallpaper.templates;
              var keys = Object.keys(t);
              var n = 0;
              for (var i = 0; i < keys.length; i++)
                if (t[keys[i]])
                  n++;
              return n;
            }
            text: "WRITES " + _enabledCount + " TEMPLATES"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            Layout.topMargin: 4
          }
        }

        Item {
          Layout.fillHeight: true
        }

        // ---- Apply buttons ----
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 6

          Item {
            Layout.fillWidth: true
            height: 32
            enabled: root.selectedFile !== null && !root.downloading
            opacity: enabled ? 1 : 0.4
            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: applyThemeHover.hovered ? Color.primary : Color.primaryContainer
              strokeColor: Color.primary
              strokeWidth: Tokens.borderModule
            }
            Text {
              anchors.centerIn: parent
              text: root.downloading ? "DOWNLOADING…" : "APPLY + THEME"
              color: applyThemeHover.hovered ? Color.mOnPrimary : Color.primaryContainerText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
              font.weight: Font.DemiBold
            }
            HoverHandler {
              id: applyThemeHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: root.applyWallpaper(true)
            }
          }

          Item {
            Layout.fillWidth: true
            height: 30
            enabled: root.selectedFile !== null && !root.downloading
            opacity: enabled ? 1 : 0.4
            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: applyOnlyHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
              strokeColor: Color.outline
              strokeWidth: Tokens.borderModule
            }
            Text {
              anchors.centerIn: parent
              text: root.downloading ? "DOWNLOADING…" : "WALLPAPER ONLY"
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
            }
            HoverHandler {
              id: applyOnlyHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: root.applyWallpaper(false)
            }
          }

          Item {
            Layout.fillWidth: true
            height: 28
            visible: root.selectedFile !== null && !root.selectedFile.isRemote
            readonly property bool armed: root.selectedFile && root.armedDeletePath === root.selectedFile.path
            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: parent.armed ? Color.error : (deleteHover.hovered ? Color.alpha(Color.error, 0.16) : "transparent")
              strokeColor: Color.alpha(Color.error, parent.armed ? 1 : 0.6)
              strokeWidth: Tokens.borderModule
            }
            Text {
              anchors.centerIn: parent
              text: parent.armed ? "CONFIRM DELETE?" : "DELETE"
              color: parent.armed ? Color.mOnError : Color.error
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.captionSize
            }
            HoverHandler {
              id: deleteHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: root.requestDelete()
            }
          }
        }
      }
    }
  }
}
}

