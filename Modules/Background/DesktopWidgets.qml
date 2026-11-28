import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Modules.Popups.Contents
import qs.Services

// Desktop cards (weather, media, Control Center) on the wallpaper layer, draggable and individually toggleable.
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
    // The Control Center card has text fields (Wi-Fi passwords); it takes the keyboard only when clicked.
    WlrLayershell.keyboardFocus: ccCard.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    visible: Settings.isLoaded && Settings.data.desktopWidgets.enabled

    // Only the cards take clicks; the rest of the window passes them through.
    mask: Region {
      regions: [weatherRegion, mediaRegion, ccRegion]
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
      id: ccRegion
      item: ccCard.visible ? ccCard : null
    }

    // Windows on this monitor's workspace hide the cards; the Control Center card pauses its sampling then.
    readonly property var hyprMonitor: Hyprland.monitorFor(window.screen)
    readonly property bool covered: {
      const ws = window.hyprMonitor ? window.hyprMonitor.activeWorkspace : null;
      return !!(ws && ws.toplevels && ws.toplevels.values.length > 0);
    }

    // Corner placement clears whichever edge the bar occupies.
    readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(screen?.name) : "top"
    readonly property int _baseMargin: 20
    readonly property int _barGap: Tokens.barExtent + Tokens.barMargin + 12
    readonly property int _marginBottom: _baseMargin + (_barPos === "bottom" ? _barGap : 0)
    readonly property int _marginLeft: _baseMargin + (_barPos === "left" ? _barGap : 0)
    readonly property int _marginRight: _baseMargin + (_barPos === "right" ? _barGap : 0)

    readonly property bool weatherReady: Weather.ready
    readonly property var activePlayer: MediaService.activePlayer
    readonly property bool hasPlayer: !!activePlayer
    readonly property bool isPlaying: MediaService.isPlaying
    readonly property real _position: MediaService.position
    readonly property real _length: MediaService.length

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

      // Dragging breaks the x/y binding, so restore it when "Reset position" sets these back to -1 (docs/qml-gotchas.md).
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
        fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
        strokeColor: Colors.outline
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

    // --- Media card: bottom-right by default, hidden without an MPRIS player ---
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
        fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
        strokeColor: Colors.outline
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
              fillColor: Colors.surfaceContainer
              strokeColor: Colors.outline
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
              color: Colors.labelText
              font.pixelSize: Tokens.bodySize
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            NText {
              Layout.fillWidth: true
              text: window.activePlayer ? window.activePlayer.trackTitle : ""
              color: Colors.surfaceText
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              maximumLineCount: 1
            }
            NText {
              Layout.fillWidth: true
              text: window.activePlayer ? window.activePlayer.trackArtist : ""
              color: Colors.labelText
              size: NText.Size.Caption
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
          filledColor: Colors.primary
          emptyColor: Colors.surfaceContainerHigh
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

    // --- Control Center card: the full panel, on the screen picked in settings, dragged by its top strip ---
    Item {
      id: ccCard
      readonly property string targetName: Settings.data.desktopWidgets.controlCenterScreen !== "" ? Settings.data.desktopWidgets.controlCenterScreen : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
      readonly property real margins: Tokens.spaceXl
      readonly property real gripHeight: 14
      visible: Settings.data.desktopWidgets.controlCenterEnabled && window.screen && window.screen.name === ccCard.targetName
      width: (ccContent.widePage ? 520 : 436)
      height: ccCard.gripHeight + ccContent.implicitHeight + ccCard.margins * 2
      x: Settings.data.desktopWidgets.controlCenterX >= 0 ? Settings.data.desktopWidgets.controlCenterX : window._marginLeft
      y: Settings.data.desktopWidgets.controlCenterY >= 0 ? Settings.data.desktopWidgets.controlCenterY : window._baseMargin + (window._barPos === "top" ? window._barGap : 0)

      Behavior on width {
        NumberAnimation {
          duration: Tokens.durationSidebarSlide
          easing.type: Tokens.easingSidebarSlide
        }
      }

      // Dragging breaks the x/y binding, so restore it when "Reset position" sets these back to -1 (docs/qml-gotchas.md).
      Connections {
        target: Settings.data.desktopWidgets
        function onControlCenterXChanged() {
          if (Settings.data.desktopWidgets.controlCenterX < 0)
            ccCard.x = Qt.binding(function () {
              return Settings.data.desktopWidgets.controlCenterX >= 0 ? Settings.data.desktopWidgets.controlCenterX : window._marginLeft;
            });
        }
        function onControlCenterYChanged() {
          if (Settings.data.desktopWidgets.controlCenterY < 0)
            ccCard.y = Qt.binding(function () {
              return Settings.data.desktopWidgets.controlCenterY >= 0 ? Settings.data.desktopWidgets.controlCenterY : window._baseMargin + (window._barPos === "top" ? window._barGap : 0);
            });
        }
      }

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferPanel
        cutTopRight: true
        cutBottomLeft: true
        fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
        strokeColor: Colors.outline
        strokeWidth: Tokens.borderPanel
      }

      // Drag strip: the panel's own controls keep their clicks and drags.
      Item {
        id: grip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Tokens.spaceSm
        height: ccCard.gripHeight

        Row {
          anchors.centerIn: parent
          spacing: 3
          Repeater {
            model: 6
            Rectangle {
              width: 3
              height: 3
              color: gripHover.hovered || gripDrag.active ? Colors.primary : Colors.outline
            }
          }
        }

        HoverHandler {
          id: gripHover
          cursorShape: gripDrag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        }
        DragHandler {
          id: gripDrag
          target: ccCard
          xAxis.minimum: 0
          xAxis.maximum: window.width - ccCard.width
          yAxis.minimum: 0
          yAxis.maximum: window.height - ccCard.height
          onActiveChanged: {
            if (!active) {
              Settings.data.desktopWidgets.controlCenterX = ccCard.x;
              Settings.data.desktopWidgets.controlCenterY = ccCard.y;
            }
          }
        }
      }

      ControlCenterPopupContent {
        id: ccContent
        x: ccCard.margins
        y: ccCard.margins + ccCard.gripHeight - Tokens.spaceSm
        width: ccCard.width - ccCard.margins * 2
        height: implicitHeight
        active: ccCard.visible && !window.covered
        targetScreen: window.screen
        // Nothing to close on the desktop; go back to the main page instead.
        onRequestClose: ccContent.page = ""
      }
    }
  }
}
