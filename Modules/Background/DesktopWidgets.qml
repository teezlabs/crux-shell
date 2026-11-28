import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Widgets
import qs.Modules.ControlCenter
import qs.Services

// Desktop cards (weather, music, clock) on the wallpaper layer. Locked normally; DesktopEdit mode shows a grid,
// and the cards drag, snap and resize (DesktopCard).
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: window
    required property var modelData
    screen: modelData

    color: "transparent"
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "crux-desktop-widgets"
    exclusionMode: ExclusionMode.Ignore

    visible: Settings.isLoaded && Settings.data.desktopWidgets.enabled

    // Only the cards take clicks; in edit mode the whole screen does, for the grid and toolbar.
    mask: Region {
      item: DesktopEdit.active ? fullArea : null
      regions: DesktopEdit.active ? [] : [weatherRegion, mediaRegion, clockRegion]
    }

    Item {
      id: fullArea
      anchors.fill: parent
    }
    Region {
      id: weatherRegion
      item: weatherCard.visible ? weatherCard : null
    }
    Region {
      id: mediaRegion
      item: mediaCard.visible ? mediaCard : null
    }
    Region {
      id: clockRegion
      item: clockCard.visible ? clockCard : null
    }

    // Corner placement clears whichever edge the bar occupies.
    readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(screen?.name) : "top"
    readonly property int _baseMargin: 20
    readonly property int _barGap: Tokens.barExtent + Tokens.barMargin + 12
    readonly property int _marginTop: _baseMargin + (_barPos === "top" ? _barGap : 0)
    readonly property int _marginBottom: _baseMargin + (_barPos === "bottom" ? _barGap : 0)
    readonly property int _marginLeft: _baseMargin + (_barPos === "left" ? _barGap : 0)
    readonly property int _marginRight: _baseMargin + (_barPos === "right" ? _barGap : 0)

    // Windows on this monitor's workspace hide the cards; live work (the visualizer) pauses then.
    readonly property var hyprMonitor: Hyprland.monitorFor(window.screen)
    readonly property bool covered: {
      const ws = window.hyprMonitor ? window.hyprMonitor.activeWorkspace : null;
      return !!(ws && ws.toplevels && ws.toplevels.values.length > 0);
    }

    // Grid cell near 1.5% of the width, chosen so lines cross the screen centre (after noctalia's legacy-v4).
    readonly property int gridSize: {
      const base = Math.max(20, Math.min(60, Math.round(window.width * 0.015)));
      const cx = Math.round(window.width / 2);
      const cy = Math.round(window.height / 2);
      let best = base;
      let bestMiss = Infinity;
      for (let c = Math.max(20, base - 10); c <= Math.min(60, base + 10); c++) {
        const miss = (cx % c) + (cy % c);
        if (miss < bestMiss || (miss === bestMiss && Math.abs(c - base) < Math.abs(best - base))) {
          best = c;
          bestMiss = miss;
        }
      }
      return best;
    }

    // ---- Edit mode grid ----
    Canvas {
      id: grid
      anchors.fill: parent
      visible: DesktopEdit.active
      readonly property color lineColor: Colors.primary
      readonly property real cell: window.gridSize
      readonly property bool snapping: Settings.data.desktopWidgets.gridSnap
      onVisibleChanged: if (visible)
        requestPaint()
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      onLineColorChanged: requestPaint()
      onCellChanged: requestPaint()
      onSnappingChanged: requestPaint()
      onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = Colors.alpha(Colors.surface, 0.35);
        ctx.fillRect(0, 0, width, height);
        if (!snapping)
          return;
        // Lines start at the centre and step outwards, so the centre lines are always drawn.
        const cx = Math.round(width / 2);
        const cy = Math.round(height / 2);
        ctx.lineWidth = 1;
        ctx.strokeStyle = Colors.alpha(lineColor, 0.18);
        ctx.beginPath();
        for (let x = cx % cell; x <= width; x += cell) {
          ctx.moveTo(Math.round(x) + 0.5, 0);
          ctx.lineTo(Math.round(x) + 0.5, height);
        }
        for (let y = cy % cell; y <= height; y += cell) {
          ctx.moveTo(0, Math.round(y) + 0.5);
          ctx.lineTo(width, Math.round(y) + 0.5);
        }
        ctx.stroke();
        ctx.strokeStyle = Colors.alpha(lineColor, 0.45);
        ctx.beginPath();
        ctx.moveTo(cx + 0.5, 0);
        ctx.lineTo(cx + 0.5, height);
        ctx.moveTo(0, cy + 0.5);
        ctx.lineTo(width, cy + 0.5);
        ctx.stroke();
      }
    }

    // ---- Edit mode toolbar, top centre below the bar ----
    Item {
      id: toolbar
      visible: DesktopEdit.active
      z: 20
      anchors.horizontalCenter: parent.horizontalCenter
      y: window._marginTop
      width: toolRow.implicitWidth + Tokens.spaceLg * 2
      height: toolRow.implicitHeight + Tokens.spaceMd * 2

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferPanel
        cutTopRight: true
        cutBottomLeft: true
        fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
        strokeColor: Colors.primary
        strokeWidth: Tokens.borderPanel
      }

      RowLayout {
        id: toolRow
        anchors.centerIn: parent
        spacing: Tokens.spaceMd

        NText {
          text: "EDITING DESKTOP"
          tracking: true
          size: NText.Size.LabelXs
          font.weight: Font.DemiBold
          color: Colors.primary
        }
        NText {
          text: "Drag to move · corner to resize"
          size: NText.Size.Caption
          color: Colors.labelText
        }
        NText {
          text: "SNAP"
          tracking: true
          size: NText.Size.LabelXs
          color: Colors.labelText
          Layout.leftMargin: Tokens.spaceMd
        }
        NToggle {
          checked: Settings.data.desktopWidgets.gridSnap
          onToggled: checked => Settings.data.desktopWidgets.gridSnap = checked
        }
        NButton {
          text: "Done"
          onClicked: DesktopEdit.active = false
        }
      }
    }

    // --- Weather card: bottom-left by default ---
    DesktopCard {
      id: weatherCard
      key: "weather"
      label: "WEATHER"
      area: fullArea
      gridSize: window.gridSize
      visible: Weather.ready && Settings.data.desktopWidgets.weatherEnabled
      contentWidth: 192
      contentHeight: weatherColumn.implicitHeight
      cutTopRight: true
      cutBottomLeft: false
      defaultX: window._marginLeft
      defaultY: window.height - height - window._marginBottom

      ColumnLayout {
        id: weatherColumn
        width: parent.width
        spacing: 8

        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          WeatherIcon {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            category: Weather.iconCategory(Weather.currentWeatherCode)
            strokeColor: Colors.surfaceText
            accentColor: Colors.tertiary
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            NText {
              text: isNaN(Weather.currentTempF) ? "--°" : Math.round(Weather.currentTempF) + "°"
              color: Colors.surfaceText
              size: NText.Size.BodyLg
              font.weight: Font.DemiBold
            }
            NText {
              Layout.fillWidth: true
              text: Weather.cityName
              color: Colors.labelText
              size: NText.Size.Caption
              elide: Text.ElideRight
            }
          }
        }

        // Compact multi-day strip — up to 4 days beyond today.
        RowLayout {
          Layout.fillWidth: true
          spacing: 10
          visible: Weather.daily.length > 1

          Repeater {
            model: Math.min(4, Math.max(0, Weather.daily.length - 1))

            delegate: ColumnLayout {
              required property int index
              readonly property var _day: Weather.daily[index + 1]
              Layout.fillWidth: true
              spacing: 2

              NText {
                tracking: true
                Layout.alignment: Qt.AlignHCenter
                text: _day ? _day.dayName : ""
                color: Colors.labelText
                size: NText.Size.LabelXs
              }
              WeatherIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                category: _day ? Weather.iconCategory(_day.weatherCode) : "cloud"
                strokeColor: Colors.surfaceTextMuted
                accentColor: Colors.tertiary
              }
              NText {
                Layout.alignment: Qt.AlignHCenter
                text: _day ? _day.tempMaxF + "°" : ""
                color: Colors.surfaceTextMuted
                size: NText.Size.LabelXs
              }
            }
          }
        }
      }
    }

    // --- Music card: the Control Center's media card, bottom-right by default, hidden without a player ---
    DesktopCard {
      id: mediaCard
      key: "media"
      label: "MUSIC"
      area: fullArea
      gridSize: window.gridSize
      readonly property var player: MediaService.activePlayer
      visible: !!player && Settings.data.desktopWidgets.mediaEnabled
      contentWidth: 340
      contentHeight: mediaColumn.implicitHeight
      cutTopLeft: true
      cutTopRight: false
      cutBottomLeft: false
      defaultX: window.width - width - window._marginRight
      defaultY: window.height - height - window._marginBottom

      ColumnLayout {
        id: mediaColumn
        width: parent.width
        spacing: Tokens.spaceMd

        RowLayout {
          Layout.fillWidth: true
          spacing: Tokens.spaceLg

          Item {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 52

            Rectangle {
              anchors.fill: parent
              color: Colors.surfaceContainerHigh
            }
            Image {
              id: cover
              anchors.fill: parent
              source: mediaCard.player ? (mediaCard.player.trackArtUrl || "") : ""
              sourceSize.width: 104
              sourceSize.height: 104
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
            }
            NSymbol {
              anchors.centerIn: parent
              visible: cover.status !== Image.Ready
              name: "music_note"
              size: 24
              color: Colors.labelText
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spaceXs

            NText {
              Layout.fillWidth: true
              text: mediaCard.player ? (mediaCard.player.trackTitle || mediaCard.player.identity) : ""
              size: NText.Size.BodySm
              font.weight: Font.DemiBold
              elide: Text.ElideRight
            }
            NText {
              Layout.fillWidth: true
              text: mediaCard.player ? (mediaCard.player.trackArtist || mediaCard.player.identity) : ""
              size: NText.Size.Caption
              color: Colors.labelText
              elide: Text.ElideRight
            }
            CcLevelSlider {
              Layout.fillWidth: true
              Layout.topMargin: Tokens.spaceXs
              thumbRadius: 5
              trackHeight: 3
              value: MediaService.length > 0 ? (MediaService.position / MediaService.length) * 100 : 0
              interactive: !!mediaCard.player && mediaCard.player.canSeek
              onMoved: pct => {
                if (mediaCard.player && mediaCard.player.canSeek)
                  mediaCard.player.position = (pct / 100) * MediaService.length;
              }
            }
          }

          CcIconButton {
            size: 32
            symbol: "skip_previous"
            available: !!mediaCard.player && mediaCard.player.canGoPrevious
            onTapped: mediaCard.player.previous()
          }
          CcIconButton {
            size: 36
            symbol: MediaService.isPlaying ? "pause" : "play_arrow"
            tone: "active"
            available: !!mediaCard.player && (mediaCard.player.canPlay || mediaCard.player.canPause)
            onTapped: mediaCard.player.togglePlaying()
          }
          CcIconButton {
            size: 32
            symbol: "skip_next"
            available: !!mediaCard.player && mediaCard.player.canGoNext
            onTapped: mediaCard.player.next()
          }
        }

        CcSpectrum {
          Layout.fillWidth: true
          implicitHeight: 26
          running: mediaCard.visible && window.visible && !window.covered && MediaService.isPlaying
        }
      }
    }

    // --- Clock card: big time and an optional date line, top-left by default ---
    DesktopCard {
      id: clockCard
      key: "clock"
      label: "CLOCK"
      area: fullArea
      gridSize: window.gridSize
      visible: Settings.data.desktopWidgets.clockEnabled
      padding: Tokens.spaceXl
      contentWidth: clockColumn.implicitWidth
      contentHeight: clockColumn.implicitHeight
      defaultX: window._marginLeft
      defaultY: window._marginTop

      SystemClock {
        id: clock
        precision: Settings.data.desktopWidgets.clockFormat.indexOf("s") !== -1 ? SystemClock.Seconds : SystemClock.Minutes
      }

      ColumnLayout {
        id: clockColumn
        spacing: Tokens.spaceSm

        NText {
          Layout.alignment: Qt.AlignHCenter
          text: Qt.formatDateTime(clock.date, Settings.data.desktopWidgets.clockFormat)
          size: NText.Size.Display
          color: Colors.primary
          font.features: {
            "tnum": 1
          }
        }
        NText {
          Layout.alignment: Qt.AlignHCenter
          visible: Settings.data.desktopWidgets.clockDateFormat !== ""
          text: Qt.formatDateTime(clock.date, Settings.data.desktopWidgets.clockDateFormat).toUpperCase()
          tracking: true
          size: NText.Size.BodyLg
          color: Colors.labelText
        }
      }
    }
  }
}
