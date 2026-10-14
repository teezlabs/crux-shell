import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Widgets
import qs.Services

// Wallpaper browser: centered floating card (not the spec's fullscreen mockup). Local library only. See crux skill's notes.md.
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
    }
  }

  // Forwards the rail's search box into the shared service.
  function whSearch(page, append) {
    Wallhaven.query = root.searchText;
    Wallhaven.search(page, append);
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
    if (Settings.data.wallpaper.closeOnSelect)
      root.close();
  }

  // Arm-then-confirm (same convention as the session menu's destructive
  // actions) — the delete button reads "DELETE" once, "CONFIRM DELETE?" for
  // a few seconds after, and only actually removes the file on that second
  // click. Armed state is keyed by path so switching selection disarms it.
  // The service resets nothing UI-side; a fresh result set means the
  // selection has to go back to the top.
  Connections {
    target: Wallhaven
    function onResultsReplaced() {
      root.selectedIndex = 0;
    }
  }

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
      fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
      shadow: true
      rimLight: true
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
        color: Colors.primary
      }
      NText {
        tracking: true
        text: "WALLPAPER BROWSER"
        color: Colors.surfaceText
        size: NText.Size.BodyLg
        font.weight: Font.DemiBold
        font.letterSpacing: 1
      }
      Item {
        Layout.fillWidth: true
      }
      NText {
        text: root.sourceMode === "wallhaven" ? (Wallhaven.loading ? "SEARCHING…" : Wallhaven.results.length + " RESULTS" + (Wallhaven.error ? " · " + Wallhaven.error : "")) : root.filteredFiles.length + " OF " + root.files.length
        color: Colors.labelText
        size: NText.Size.Caption
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
                fillColor: srcPill.selected ? Colors.primary : Colors.surfaceContainer
              }
              NText {
                anchors.centerIn: parent
                text: srcPill.modelData.label
                color: srcPill.selected ? Colors.primaryText : Colors.surfaceText
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
                  if (root.sourceMode === "wallhaven" && Wallhaven.results.length === 0)
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
            fillColor: Colors.surface
            strokeColor: Colors.primary
            strokeWidth: searchInput.activeFocus ? Tokens.borderModule : 0
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
            onTextChanged: {
              root.searchText = text;
              if (root.sourceMode === "local")
                root.selectedIndex = 0;
            }
            onAccepted: if (root.sourceMode === "wallhaven")
              root.whSearch(1, false)

            NText {
              anchors.centerIn: parent
              visible: parent.text === "" && !parent.activeFocus
              text: root.sourceMode === "wallhaven" ? "/ SEARCH WALLHAVEN ⏎" : "/ SEARCH"
              color: Colors.labelText
              size: NText.Size.BodySm
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          NText {
            tracking: true
            text: "SORT"
            color: Colors.labelText
            size: NText.Size.LabelXs
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
                readonly property bool selected: root.sourceMode === "wallhaven" ? Wallhaven.sorting === modelData.key : root.sortMode === modelData.key
                width: sortLabel.implicitWidth + 18
                height: 24
                Chamfer {
                  anchors.fill: parent
                  chamferSize: Tokens.chamferIcon
                  cutTopRight: true
                  cutBottomLeft: true
                  fillColor: sortPill.selected ? Colors.primary : Colors.surfaceContainer
                }
                NText {
                  id: sortLabel
                  anchors.centerIn: parent
                  text: sortPill.modelData.label
                  color: sortPill.selected ? Colors.primaryText : Colors.surfaceText
                  size: NText.Size.LabelXs
                }
                HoverHandler {
                  cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                  onTapped: {
                    if (root.sourceMode === "wallhaven") {
                      Wallhaven.sorting = sortPill.modelData.key;
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
          NText {
            tracking: true
            text: "PURITY"
            color: Colors.labelText
            size: NText.Size.LabelXs
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
                  fillColor: purityPill.selected ? Colors.primary : Colors.surfaceContainer
                }
                NText {
                  id: purityLabel
                  anchors.centerIn: parent
                  text: purityPill.modelData.label
                  color: purityPill.selected ? Colors.primaryText : Colors.surfaceText
                  size: NText.Size.LabelXs
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
          NText {
            tracking: true
            text: "QUALITY / RATIO"
            color: Colors.labelText
            size: NText.Size.LabelXs
          }
          NComboBox {
            Layout.fillWidth: true
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
            Layout.fillWidth: true
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
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          NText {
            tracking: true
            text: "DIRECTORY"
            color: Colors.labelText
            size: NText.Size.LabelXs
          }
          Item {
            Layout.fillWidth: true
            height: 26
            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Colors.surface
              strokeColor: Colors.primary
              strokeWidth: dirInput.activeFocus ? Tokens.borderModule : 0
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

        NText {
          text: "← → ↑ ↓ MOVE\n⏎ APPLY + THEME\n⇧⏎ WALLPAPER ONLY\n/ SEARCH  R RANDOM\nESC CLOSE"
          color: Colors.labelText
          size: NText.Size.LabelXs
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
                fillColor: Colors.surfaceContainer
                strokeColor: Colors.primary
                strokeWidth: thumb.isSelected ? 2 : 0
              }

              Image {
                id: thumbImage
                anchors.fill: parent
                anchors.margins: thumb.isSelected ? 2 : 1
                source: thumb.isVideo ? "" : thumb.isRemote ? thumb.modelData.thumb : "file://" + thumb.modelData.path
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                // Decode at the size actually drawn. Without this a 4K
                // wallpaper is decoded whole to fill a ~220px cell; the
                // library here is 141 MPix across 26 files.
                sourceSize.width: Math.max(1, Math.round(width))
                sourceSize.height: Math.max(1, Math.round(height))
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
                  color: thumb.isVideo ? Colors.alpha(Colors.tertiary, 0.85) : thumb.isRemote ? Colors.alpha(Colors.primary, 0.85) : Colors.alpha(Colors.surface, 0.75)
                }
                NText {
                  id: badgeLabel
                  anchors.centerIn: parent
                  text: thumb.isVideo ? "VID" : thumb.isRemote ? "WEB" : "IMG"
                  color: (thumb.isVideo || thumb.isRemote) ? Colors.primaryText : Colors.labelText
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
            visible: root.sourceMode === "wallhaven" && Wallhaven.page < Wallhaven.lastPage
            Layout.columnSpan: root._columns
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            Layout.topMargin: 4

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: loadMoreHover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
            }
            NText {
              anchors.centerIn: parent
              text: Wallhaven.loading ? "LOADING…" : "LOAD MORE"
              color: Colors.surfaceText
              size: NText.Size.LabelXs
            }
            HoverHandler {
              id: loadMoreHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: root.whSearch(Wallhaven.page + 1, true)
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
            fillColor: Colors.surfaceContainer
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

          NText {
            visible: !root.selectedFile
            anchors.centerIn: parent
            text: "NO SELECTION"
            color: Colors.labelText
            size: NText.Size.LabelXs
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2
          visible: root.selectedFile !== null
          NText {
            text: root.selectedFile ? root.selectedFile.name : ""
            color: Colors.surfaceText
            size: NText.Size.BodySm
            elide: Text.ElideMiddle
            Layout.fillWidth: true
          }
          NText {
            text: Settings.data.wallpaper.directory
            color: Colors.labelText
            size: NText.Size.Caption
            elide: Text.ElideMiddle
            Layout.fillWidth: true
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Colors.surfaceContainerHigh
        }

        // ---- Monitor targeting ----
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          NText {
            tracking: true
            text: "TARGET"
            color: Colors.labelText
            size: NText.Size.LabelXs
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
                fillColor: allPill.selected ? Colors.primary : Colors.surfaceContainer
              }
              NText {
                id: allLabel
                anchors.centerIn: parent
                text: "ALL"
                color: allPill.selected ? Colors.primaryText : Colors.surfaceText
                size: NText.Size.LabelXs
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
                  fillColor: monPill.selected ? Colors.primary : Colors.surfaceContainer
                }
                NText {
                  id: monLabel
                  anchors.centerIn: parent
                  text: monPill.modelData.name + (monPill.modelData === Quickshell.screens[0] ? " ★" : "")
                  color: monPill.selected ? Colors.primaryText : Colors.surfaceText
                  size: NText.Size.LabelXs
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
          color: Colors.surfaceContainerHigh
        }

        // ---- Matugen scheme + templates ----
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          NText {
            tracking: true
            text: "SCHEME"
            color: Colors.labelText
            size: NText.Size.LabelXs
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
                  fillColor: schemePill.selected ? Colors.primary : Colors.surfaceContainer
                }
                NText {
                  id: schemeLabel
                  anchors.centerIn: parent
                  text: schemePill.label
                  color: schemePill.selected ? Colors.primaryText : Colors.surfaceText
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
          NText {
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
            color: Colors.labelText
            size: NText.Size.LabelXs
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
              fillColor: applyThemeHover.hovered ? Colors.primary : Colors.primaryContainer
              strokeColor: Colors.primary
              strokeWidth: Tokens.borderModule
            }
            NText {
              anchors.centerIn: parent
              text: root.downloading ? "DOWNLOADING…" : "APPLY + THEME"
              color: applyThemeHover.hovered ? Colors.primaryText : Colors.primaryContainerText
              size: NText.Size.BodySm
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

          NButton {
            Layout.fillWidth: true
            enabled: root.selectedFile !== null && !root.downloading
            text: root.downloading ? "DOWNLOADING…" : "WALLPAPER ONLY"
            onClicked: root.applyWallpaper(false)
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
              fillColor: parent.armed ? Colors.error : (deleteHover.hovered ? Colors.alpha(Colors.error, 0.16) : "transparent")
              strokeColor: Colors.alpha(Colors.error, parent.armed ? 1 : 0.6)
              strokeWidth: Tokens.borderModule
            }
            NText {
              anchors.centerIn: parent
              text: parent.armed ? "CONFIRM DELETE?" : "DELETE"
              color: parent.armed ? Colors.errorText : Colors.error
              size: NText.Size.Caption
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

