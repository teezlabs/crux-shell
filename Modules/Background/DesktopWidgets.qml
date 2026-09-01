import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.Commons
import qs.Modules.Bar.Extras

// Desktop info cards (weather, media), pinned to the wallpaper layer,
// draggable, individually toggleable. See crux skill's notes.md.
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

    // Only the two cards below are ever click-targetable; everywhere else
    // on this full-screen transparent window passes clicks straight through
    // to whatever's behind it (desktop, or a window under it).
    mask: Region {
      regions: [weatherRegion, mediaRegion]
    }

    Region {
      id: weatherRegion
      item: weatherCard.visible ? weatherCard : null
    }
    Region {
      id: mediaRegion
      item: mediaCard.visible ? mediaCard : null
    }

    // Bar-aware corner placement: nudge off whichever screen edge(s) the
    // bar currently occupies (position + thickness + its own float margin)
    // so a floating bar never overlaps a card, plus a flat base margin
    // otherwise.
    readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(screen?.name) : "top"
    readonly property int _baseMargin: 20
    readonly property int _barGap: Settings.data.bar.thickness + Settings.data.bar.floatMargin * 2 + 12
    readonly property int _marginBottom: _baseMargin + (_barPos === "bottom" ? _barGap : 0)
    readonly property int _marginLeft: _baseMargin + (_barPos === "left" ? _barGap : 0)
    readonly property int _marginRight: _baseMargin + (_barPos === "right" ? _barGap : 0)

    readonly property bool weatherReady: Weather.ready
    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var activePlayer: {
      for (var i = 0; i < players.length; i++) {
        if (players[i] && players[i].playbackState === MprisPlaybackState.Playing)
          return players[i];
      }
      return players.length > 0 ? players[0] : null;
    }
    readonly property bool hasPlayer: !!activePlayer
    readonly property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false

    // MPRIS position doesn't reliably push updates during playback — same
    // "read your own tick property to force a stale binding to re-run"
    // trick MediaPlayerWindow.qml already uses.
    property int _positionTick: 0
    readonly property real _position: {
      _positionTick;
      return activePlayer ? activePlayer.position : 0;
    }
    readonly property real _length: activePlayer ? activePlayer.length : 0

    Timer {
      interval: 1000
      running: window.visible && window.isPlaying
      repeat: true
      onTriggered: window._positionTick++
    }

    // --- Weather card: bottom-left corner by default, draggable ---
    Item {
      id: weatherCard
      visible: window.weatherReady && Settings.data.desktopWidgets.weatherEnabled
      width: 216
      height: weatherColumn.implicitHeight + 24
      x: Settings.data.desktopWidgets.weatherX >= 0 ? Settings.data.desktopWidgets.weatherX : window._marginLeft
      y: Settings.data.desktopWidgets.weatherY >= 0 ? Settings.data.desktopWidgets.weatherY : window.height - height - window._marginBottom

      DragHandler {
        target: weatherCard
        xAxis.minimum: 0
        xAxis.maximum: window.width - weatherCard.width
        yAxis.minimum: 0
        yAxis.maximum: window.height - weatherCard.height
        onActiveChanged: {
          if (!active) {
            Settings.data.desktopWidgets.weatherX = weatherCard.x;
            Settings.data.desktopWidgets.weatherY = weatherCard.y;
          }
        }
      }

      // A DragHandler permanently breaks a bound x/y into a plain value the
      // moment it moves its target — re-establish the declarative
      // default-corner binding when Settings.qml's "Reset position" sets
      // these back to -1, so the card actually returns to its corner
      // instead of staying stuck at its last dragged spot.
      Connections {
        target: Settings.data.desktopWidgets
        function onWeatherXChanged() {
          if (Settings.data.desktopWidgets.weatherX < 0)
            weatherCard.x = Qt.binding(function () {
              return Settings.data.desktopWidgets.weatherX >= 0 ? Settings.data.desktopWidgets.weatherX : window._marginLeft;
            });
        }
        function onWeatherYChanged() {
          if (Settings.data.desktopWidgets.weatherY < 0)
            weatherCard.y = Qt.binding(function () {
              return Settings.data.desktopWidgets.weatherY >= 0 ? Settings.data.desktopWidgets.weatherY : window.height - weatherCard.height - window._marginBottom;
            });
        }
      }

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferPanel
        cutTopLeft: false
        cutTopRight: true
        cutBottomLeft: false
        cutBottomRight: false
        fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
        strokeColor: Color.outline
        strokeWidth: Tokens.borderPanel
      }

      ColumnLayout {
        id: weatherColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          WeatherIcon {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            category: Weather.iconCategory(Weather.currentWeatherCode)
            strokeColor: Color.surfaceText
            accentColor: Color.tertiary
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: isNaN(Weather.currentTempF) ? "--°" : Math.round(Weather.currentTempF) + "°"
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodyLgSize
              font.weight: Font.DemiBold
            }
            Text {
              Layout.fillWidth: true
              text: Weather.cityName
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.captionSize
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

              Text {
                Layout.alignment: Qt.AlignHCenter
                text: _day ? _day.dayName : ""
                color: Color.labelText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.labelXsSize
                font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
              }
              WeatherIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                category: _day ? Weather.iconCategory(_day.weatherCode) : "cloud"
                strokeColor: Color.surfaceTextMuted
                accentColor: Color.tertiary
              }
              Text {
                Layout.alignment: Qt.AlignHCenter
                text: _day ? _day.tempMaxF + "°" : ""
                color: Color.surfaceTextMuted
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.labelXsSize
              }
            }
          }
        }
      }
    }

    // --- Now-playing media card: bottom-right corner by default,
    // draggable, hidden entirely when there's no active MPRIS player. ---
    Item {
      id: mediaCard
      visible: window.hasPlayer && Settings.data.desktopWidgets.mediaEnabled
      width: 300
      height: mediaColumn.implicitHeight + 24
      x: Settings.data.desktopWidgets.mediaX >= 0 ? Settings.data.desktopWidgets.mediaX : window.width - width - window._marginRight
      y: Settings.data.desktopWidgets.mediaY >= 0 ? Settings.data.desktopWidgets.mediaY : window.height - height - window._marginBottom

      DragHandler {
        target: mediaCard
        xAxis.minimum: 0
        xAxis.maximum: window.width - mediaCard.width
        yAxis.minimum: 0
        yAxis.maximum: window.height - mediaCard.height
        onActiveChanged: {
          if (!active) {
            Settings.data.desktopWidgets.mediaX = mediaCard.x;
            Settings.data.desktopWidgets.mediaY = mediaCard.y;
          }
        }
      }

      Connections {
        target: Settings.data.desktopWidgets
        function onMediaXChanged() {
          if (Settings.data.desktopWidgets.mediaX < 0)
            mediaCard.x = Qt.binding(function () {
              return Settings.data.desktopWidgets.mediaX >= 0 ? Settings.data.desktopWidgets.mediaX : window.width - mediaCard.width - window._marginRight;
            });
        }
        function onMediaYChanged() {
          if (Settings.data.desktopWidgets.mediaY < 0)
            mediaCard.y = Qt.binding(function () {
              return Settings.data.desktopWidgets.mediaY >= 0 ? Settings.data.desktopWidgets.mediaY : window.height - mediaCard.height - window._marginBottom;
            });
        }
      }

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferPanel
        cutTopLeft: true
        cutTopRight: false
        cutBottomLeft: false
        cutBottomRight: false
        fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
        strokeColor: Color.outline
        strokeWidth: Tokens.borderPanel
      }

      ColumnLayout {
        id: mediaColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Item {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Color.surfaceContainer
              strokeColor: Color.outline
              strokeWidth: Tokens.borderModule
            }

            Image {
              anchors.fill: parent
              anchors.margins: Tokens.borderModule
              visible: window.activePlayer && window.activePlayer.trackArtUrl !== ""
              source: window.activePlayer ? window.activePlayer.trackArtUrl : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
            }

            Text {
              anchors.centerIn: parent
              visible: !window.activePlayer || window.activePlayer.trackArtUrl === ""
              text: window.isPlaying ? "▶" : "⏸"
              color: Color.labelText
              font.pixelSize: Tokens.bodySize
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              Layout.fillWidth: true
              text: window.activePlayer ? window.activePlayer.trackTitle : ""
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySize
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              maximumLineCount: 1
            }
            Text {
              Layout.fillWidth: true
              text: window.activePlayer ? window.activePlayer.trackArtist : ""
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.captionSize
              elide: Text.ElideRight
              maximumLineCount: 1
            }
          }
        }

        SegMeter {
          Layout.fillWidth: true
          cellCount: Tokens.meterSidebarSeekCells
          cellHeight: Tokens.meterSidebarSeekCellHeight
          value: window._length > 0 ? (window._position / window._length) * 100 : 0
          interactive: !!window.activePlayer && window.activePlayer.canSeek
          filledColor: Color.primary
          emptyColor: Color.surfaceContainerHigh
          onMoved: pct => {
            if (window.activePlayer && window.activePlayer.canSeek)
              window.activePlayer.position = (pct / 100) * window._length;
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 1

          MpTransportButton {
            Layout.fillWidth: true
            glyph: "⏮"
            available: !!window.activePlayer && window.activePlayer.canGoPrevious
            onTapped: window.activePlayer.previous()
          }
          MpTransportButton {
            Layout.fillWidth: true
            glyph: window.isPlaying ? "⏸" : "▶"
            active: window.isPlaying
            available: !!window.activePlayer && (window.activePlayer.canPlay || window.activePlayer.canPause)
            onTapped: window.activePlayer.togglePlaying()
          }
          MpTransportButton {
            Layout.fillWidth: true
            glyph: "⏭"
            available: !!window.activePlayer && window.activePlayer.canGoNext
            onTapped: window.activePlayer.next()
          }
        }
      }
    }
  }
}
