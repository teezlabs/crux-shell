import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Widgets
import qs.Services

// Wallpaper browser: a floating card around a skwd-wall-style slice strip, local library or Wallhaven.
NPanelWindow {
  id: root

  popupName: "wallpaperBrowser"
  // Not derived from popupName: Hyprland's blur rule matches this exact
  // string (see windowrules.lua).
  surfaceNamespace: "crux-wallpaper-browser"

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
  readonly property var filteredFiles: root.sourceMode === "wallhaven" ? Wallhaven.results : root.localFiltered

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
      if (root._selectCurrentOnScan) {
        root._selectCurrentOnScan = false;
        root.selectCurrent();
      }
    }
  }

  // Forwards the rail's search box into the shared service.
  function whSearch(page, append) {
    Wallhaven.query = root.searchText;
    Wallhaven.search(page, append);
  }

  // A Wallhaven pick is downloading.
  property bool downloading: false
  property string _downloadDest: ""
  property bool _pendingWithTheme: false

  function _downloadAndApply(item, withTheme) {
    var ext = item.path.split(".").pop().split("?")[0].toLowerCase();
    if (["jpg", "jpeg", "png", "webp", "gif", "bmp"].indexOf(ext) === -1)
      ext = "jpg";
    root._downloadDest = Settings.data.wallpaper.directory + "/wallhaven-" + item.id + "." + ext;
    root._pendingWithTheme = withTheme;
    root.downloading = true;
    whDownloadProc.command = ["curl", "-fsSL", "-A", Wallhaven._userAgent, "-o", root._downloadDest, item.path];
    whDownloadProc.running = true;
  }

  Process {
    id: whDownloadProc
    onExited: exitCode => {
      root.downloading = false;
      if (exitCode !== 0) {
        Wallhaven.error = "Download failed";
        return;
      }
      Settings.setWallpaperForScreen(root.targetMonitor, root._downloadDest);
      if (root._pendingWithTheme && Settings.data.wallpaper.autoTheme)
        Matugen.generateFrom(root._downloadDest);
      // Closes here, not when the button was pressed: a wallhaven pick has
      // to finish downloading first, and closing early would hide the
      // "Download failed" the branch above sets.
      if (Settings.data.wallpaper.closeOnSelect)
        root.close();
    }
  }

  property int selectedIndex: 0
  onSelectedIndexChanged: {
    if (root.sourceMode === "local" && strip.currentIndex !== root.selectedIndex)
      strip.currentIndex = root.selectedIndex;
    if (root.sourceMode === "wallhaven") {
      whGrid.currentIndex = root.selectedIndex;
      whGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
    }
    // Wallhaven pages in as the strip nears its end.
    if (root.sourceMode === "wallhaven" && !Wallhaven.loading && Wallhaven.page < Wallhaven.lastPage && root.selectedIndex >= root.filteredFiles.length - 3)
      root.whSearch(Wallhaven.page + 1, true);
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
    if (Settings.data.wallpaper.closeOnSelect)
      root.close();
  }

  // The service resets nothing UI-side; a fresh result set means the
  // selection has to go back to the start.
  Connections {
    target: Wallhaven
    function onResultsReplaced() {
      root.selectedIndex = 0;
    }
  }

  // Arm-then-confirm, like the session menu's destructive actions: the first
  // press arms, a second within 3s deletes. Keyed by path, so moving disarms it.
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

  // Opens on the wallpaper in use, so the theme controls act on it rather than the first file.
  property bool _selectCurrentOnScan: false
  function selectCurrent() {
    const current = Settings.getWallpaperForScreen(root.targetMonitor);
    const i = root.localFiltered.findIndex(f => f.path === current);
    root.selectedIndex = i >= 0 ? i : 0;
  }

  onVisibleChanged: if (visible) {
    root.selectedIndex = 0;
    root._selectCurrentOnScan = root.sourceMode === "local";
    root.rescan();
  }

  readonly property bool portrait: root.height > root.width

  // Strip geometry, after skwd-wall's slice view: one wide focused card, narrow slices either side.
  readonly property real _expandedWidth: Math.min(768, Math.round(strip.width * 0.62))
  readonly property real _sliceHeight: Math.round(root._expandedWidth * 0.68)
  readonly property real _sliceWidth: root.portrait ? 96 : 135
  readonly property real _skew: 28
  readonly property real _sliceGap: 6

  function _moveSelection(d) {
    if (root.filteredFiles.length === 0)
      return;
    root.selectedIndex = Math.max(0, Math.min(root.filteredFiles.length - 1, root.selectedIndex + d));
  }

  // Don't steal focus into searchInput on open, or these shortcuts (gated on !activeFocus) go dead.
  Shortcut {
    sequence: "Left"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: root._moveSelection(-1)
  }
  Shortcut {
    sequence: "Right"
    enabled: root.visible && !searchInput.activeFocus
    onActivated: root._moveSelection(1)
  }
  // Wallhaven is a grid, so Up and Down step a row there.
  Shortcut {
    sequence: "Up"
    enabled: root.visible && !searchInput.activeFocus && root.sourceMode === "wallhaven"
    onActivated: root._moveSelection(-whGrid.columns)
  }
  Shortcut {
    sequence: "Down"
    enabled: root.visible && !searchInput.activeFocus && root.sourceMode === "wallhaven"
    onActivated: root._moveSelection(whGrid.columns)
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

  Item {
    id: card
    anchors.centerIn: parent
    width: Math.min(1560, root.width - 40)
    height: Math.min(layout.implicitHeight + 40, root.height - 40)

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
      strokeColor: Colors.outline
      strokeWidth: Tokens.borderPanel
      shadow: true
      rimLight: true
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: layout
      anchors.fill: parent
      anchors.margins: 20
      spacing: 14

      // ---- Header ----
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
          width: 3
          height: 20
          color: Colors.primary
        }
        NText {
          tracking: true
          text: "WALLPAPER"
          color: Colors.surfaceText
          size: NText.Size.BodyLg
          font.weight: Font.DemiBold
        }
        Item {
          Layout.fillWidth: true
        }
        NText {
          visible: !root.portrait
          tracking: true
          text: (root.sourceMode === "wallhaven" ? "← → ↑ ↓" : "← →") + " MOVE · ⏎ APPLY + THEME · ⇧⏎ WALLPAPER ONLY · / SEARCH · R RANDOM"
          color: Colors.labelText
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          text: root.sourceMode === "wallhaven" ? (Wallhaven.loading ? "SEARCHING…" : (root.selectedIndex + 1) + " / " + Wallhaven.results.length + (Wallhaven.error ? " · " + Wallhaven.error.toUpperCase() : "")) : (root.filteredFiles.length > 0 ? (root.selectedIndex + 1) + " / " + root.filteredFiles.length : "0 / " + root.files.length)
          color: Colors.labelText
          size: NText.Size.LabelXs
        }
      }

      // ---- Filter bar ----
      Flow {
        Layout.fillWidth: true
        spacing: 8

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
          delegate: BrowserPill {
            required property var modelData
            text: modelData.label
            selected: root.sourceMode === modelData.key
            onTapped: {
              root.sourceMode = modelData.key;
              root.selectedIndex = 0;
              if (root.sourceMode === "wallhaven" && Wallhaven.results.length === 0)
                root.whSearch(1, false);
            }
          }
        }

        Item {
          width: 260
          height: 24

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Colors.surface
            strokeColor: searchInput.activeFocus ? Colors.primary : Colors.outline
            strokeWidth: Tokens.borderModule
          }

          TextInput {
            id: searchInput
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: Text.AlignVCenter
            color: Colors.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
            selectByMouse: true
            clip: true
            onTextChanged: {
              root.searchText = text;
              if (root.sourceMode === "local")
                root.selectedIndex = 0;
            }
            onAccepted: if (root.sourceMode === "wallhaven")
              root.whSearch(1, false)

            NText {
              anchors.verticalCenter: parent.verticalCenter
              visible: parent.text === "" && !parent.activeFocus
              text: root.sourceMode === "wallhaven" ? "/ Search Wallhaven ⏎" : "/ Search"
              color: Colors.labelText
              size: NText.Size.BodySm
            }
          }
        }

        Repeater {
          model: root.sourceMode === "wallhaven" ? [
            {
              "key": "toplist",
              "label": "TOP"
            },
            {
              "key": "date_added",
              "label": "LATEST"
            },
            {
              "key": "views",
              "label": "VIEWS"
            },
            {
              "key": "favorites",
              "label": "FAVES"
            }
          ] : [
            {
              "key": "name",
              "label": "NAME"
            },
            {
              "key": "date",
              "label": "RECENT"
            }
          ]
          delegate: BrowserPill {
            required property var modelData
            text: modelData.label
            selected: root.sourceMode === "wallhaven" ? Wallhaven.sorting === modelData.key : root.sortMode === modelData.key
            onTapped: {
              if (root.sourceMode === "wallhaven") {
                Wallhaven.sorting = modelData.key;
                root.whSearch(1, false);
              } else {
                root.sortMode = modelData.key;
              }
            }
          }
        }

        Repeater {
          model: root.sourceMode === "wallhaven" ? [
            {
              "key": "wallhavenSfw",
              "label": "SFW"
            },
            {
              "key": "wallhavenSketchy",
              "label": "SKETCHY"
            },
            {
              "key": "wallhavenNsfw",
              "label": "NSFW"
            }
          ] : []
          delegate: BrowserPill {
            required property var modelData
            text: modelData.label
            selected: Settings.data.wallpaper[modelData.key]
            onTapped: {
              Settings.data.wallpaper[modelData.key] = !selected;
              root.whSearch(1, false);
            }
          }
        }

        NComboBox {
          visible: root.sourceMode === "wallhaven"
          width: 150
          implicitHeight: 24
          textSize: NText.Size.Caption
          label: "QUALITY"
          currentKey: Settings.data.wallpaper.wallhavenAtLeast
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

        NComboBox {
          visible: root.sourceMode === "wallhaven"
          width: 150
          implicitHeight: 24
          textSize: NText.Size.Caption
          label: "RATIO"
          currentKey: Settings.data.wallpaper.wallhavenRatio
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

        Item {
          visible: root.sourceMode === "local"
          width: 300
          height: 24
          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Colors.surface
            strokeColor: dirInput.activeFocus ? Colors.primary : Colors.outline
            strokeWidth: Tokens.borderModule
          }
          TextInput {
            id: dirInput
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            text: Settings.data.wallpaper.directory
            color: Colors.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.captionSize
            selectByMouse: true
            clip: true
            onEditingFinished: {
              Settings.data.wallpaper.directory = text;
              root.rescan();
            }
          }
        }
      }

      // ---- Slice strip (local library) ----
      ListView {
        id: strip
        visible: root.sourceMode === "local"
        Layout.fillWidth: true
        Layout.preferredHeight: root._sliceHeight
        orientation: ListView.Horizontal
        model: visible ? root.filteredFiles : []
        // Negative spacing lets neighbouring slants run parallel with a small gap.
        spacing: root._sliceGap - root._skew
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - root._expandedWidth) / 2
        preferredHighlightEnd: (width + root._expandedWidth) / 2
        highlightMoveDuration: Tokens.durationSidebarSlide
        cacheBuffer: root._expandedWidth
        header: Item {
          width: (strip.width - root._expandedWidth) / 2
          height: 1
        }
        footer: Item {
          width: (strip.width - root._expandedWidth) / 2
          height: 1
        }

        onCurrentIndexChanged: if (root.selectedIndex !== currentIndex && currentIndex >= 0)
          root.selectedIndex = currentIndex

        delegate: WallpaperSlice {
          sliceWidth: root._sliceWidth
          expandedWidth: root._expandedWidth
          skew: root._skew
          onPicked: i => root.selectedIndex = i
          onApplyRequested: root.applyWallpaper(true)
        }

        // A vertical wheel steps through the strip one slice per notch.
        WheelHandler {
          acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
          onWheel: event => root._moveSelection(event.angleDelta.y > 0 || event.angleDelta.x > 0 ? -1 : 1)
        }

        NText {
          anchors.centerIn: parent
          visible: root.filteredFiles.length === 0
          tracking: true
          text: "NOTHING HERE"
          color: Colors.labelText
          size: NText.Size.LabelXs
        }
      }

      // ---- Wallhaven grid ----
      // Thumbnails sit 3px inside a 5px chamfer, enough for their corners to clear the cut,
      // so no mask effect is needed.
      GridView {
        id: whGrid
        visible: root.sourceMode === "wallhaven"
        Layout.fillWidth: true
        Layout.preferredHeight: root._sliceHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: visible ? root.filteredFiles : []
        readonly property int columns: Math.max(1, Math.floor(width / 240))
        cellWidth: Math.floor(width / columns)
        cellHeight: Math.round((cellWidth - 8) * 9 / 16) + 8

        onCurrentIndexChanged: if (visible && root.selectedIndex !== currentIndex && currentIndex >= 0)
          root.selectedIndex = currentIndex
        // Pages in more results as the grid nears its end.
        onContentYChanged: if (visible && contentHeight > 0 && contentY + height > contentHeight - cellHeight * 2 && !Wallhaven.loading && Wallhaven.page < Wallhaven.lastPage)
          root.whSearch(Wallhaven.page + 1, true)

        delegate: Item {
          id: cell
          required property var modelData
          required property int index
          readonly property bool selected: index === root.selectedIndex
          width: whGrid.cellWidth
          height: whGrid.cellHeight

          Item {
            anchors.fill: parent
            anchors.margins: 4

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Colors.surfaceContainer
              strokeColor: cell.selected ? Colors.primary : (cellHover.hovered ? Colors.alpha(Colors.primary, 0.5) : Colors.outline)
              strokeWidth: cell.selected ? 2 : Tokens.borderModule
            }

            Image {
              anchors.fill: parent
              anchors.margins: 3
              source: cell.modelData.thumb
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
              sourceSize: Qt.size(width, height)
              opacity: status === Image.Ready ? 1 : 0
              Behavior on opacity {
                NumberAnimation {
                  duration: Tokens.durationPanel
                }
              }
            }

            HoverHandler {
              id: cellHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: root.selectedIndex = cell.index
              onDoubleTapped: root.applyWallpaper(true)
            }
          }
        }

        NText {
          anchors.centerIn: parent
          visible: root.filteredFiles.length === 0
          tracking: true
          text: Wallhaven.loading ? "SEARCHING…" : (Wallhaven.error ? Wallhaven.error.toUpperCase() : "NO RESULTS")
          color: Colors.labelText
          size: NText.Size.LabelXs
        }
      }

      // ---- Footer: what's focused, where it goes, how it's themed ----
      GridLayout {
        Layout.fillWidth: true
        columns: root.portrait ? 1 : 2
        rowSpacing: 10
        columnSpacing: 20

        Flow {
          Layout.fillWidth: true
          spacing: 8

          NText {
            width: Math.min(implicitWidth, 320)
            height: 24
            verticalAlignment: Text.AlignVCenter
            text: root.selectedFile ? root.selectedFile.name : ""
            color: Colors.surfaceText
            size: NText.Size.BodySm
            elide: Text.ElideMiddle
          }

          NText {
            height: 24
            verticalAlignment: Text.AlignVCenter
            tracking: true
            text: "TARGET"
            color: Colors.labelText
            size: NText.Size.LabelXs
          }
          BrowserPill {
            text: "ALL"
            selected: root.targetMonitor === ""
            onTapped: root.targetMonitor = ""
          }
          Repeater {
            model: Quickshell.screens
            delegate: BrowserPill {
              required property var modelData
              text: modelData.name
              selected: root.targetMonitor === modelData.name
              onTapped: root.targetMonitor = modelData.name
            }
          }

          NText {
            height: 24
            verticalAlignment: Text.AlignVCenter
            tracking: true
            text: "SCHEME"
            color: Colors.labelText
            size: NText.Size.LabelXs
          }
          NComboBox {
            width: 150
            implicitHeight: 24
            textSize: NText.Size.Caption
            currentKey: Settings.data.wallpaper.matugenScheme
            model: ["scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-tonal-spot", "scheme-vibrant"].map(s => ({
                                                                                                                                                                                                  "key": s,
                                                                                                                                                                                                  "label": s.replace("scheme-", "")
                                                                                                                                                                                                }))
            onSelected: key => {
              Settings.data.wallpaper.matugenScheme = key;
              // Live preview; a Wallhaven pick has no local file until it's applied.
              if (root.selectedFile && !root.selectedFile.isRemote)
                Matugen.generateFrom(root.selectedFile.path);
            }
          }
        }

        RowLayout {
          Layout.alignment: root.portrait ? Qt.AlignLeft : Qt.AlignRight
          spacing: 8

          Item {
            visible: root.selectedFile !== null && !root.selectedFile.isRemote
            readonly property bool armed: root.selectedFile && root.armedDeletePath === root.selectedFile.path
            implicitWidth: deleteLabel.implicitWidth + 24
            implicitHeight: 30
            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: parent.armed ? Colors.error : (deleteHover.hovered ? Colors.alpha(Colors.error, 0.16) : "transparent")
              strokeColor: Colors.alpha(Colors.error, parent.armed ? 1 : 0.6)
              strokeWidth: Tokens.borderModule
            }
            NText {
              id: deleteLabel
              anchors.centerIn: parent
              tracking: true
              text: parent.armed ? "CONFIRM DELETE?" : "DELETE"
              color: parent.armed ? Colors.errorText : Colors.error
              size: NText.Size.LabelXs
            }
            HoverHandler {
              id: deleteHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: root.requestDelete()
            }
          }

          NButton {
            enabled: root.selectedFile !== null && !root.downloading
            opacity: enabled ? 1 : 0.4
            text: root.downloading ? "DOWNLOADING…" : "WALLPAPER ONLY"
            onClicked: root.applyWallpaper(false)
          }

          NButton {
            variant: "accent"
            enabled: root.selectedFile !== null && !root.downloading
            opacity: enabled ? 1 : 0.4
            text: root.downloading ? "DOWNLOADING…" : "APPLY + THEME"
            onClicked: root.applyWallpaper(true)
          }
        }
      }
    }
  }
}
