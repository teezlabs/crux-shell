import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// Desktop wallpaper layer, one PanelWindow per screen. Shader-based switch
// transitions ported from noctalia-shell — see crux skill's notes.md.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    color: "transparent"
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "crux-wallpaper"
    exclusionMode: ExclusionMode.Ignore

    readonly property string shaderDir: Quickshell.shellDir + "/Assets/Shaders/"
    readonly property string targetPath: Settings.isLoaded ? Settings.getWallpaperForScreen(modelData.name) : ""
    readonly property string targetUrl: targetPath ? "file://" + targetPath : ""
    readonly property var allTransitions: ["fade", "wipe", "disc", "stripes", "pixelate", "honeycomb"]

    property bool initialized: false
    property string transitionType: "fade"
    property real transitionProgress: 0

    // Per-transition randomized parameters, picked fresh each switch.
    property real wipeDirection: 0 // 0=left, 1=right, 2=up, 3=down
    property real discCenterX: 0.5
    property real discCenterY: 0.5
    property real stripesCount: 16
    property real stripesAngle: 0
    property real pixelateMaxBlockSize: 64.0
    property real honeycombCellSize: 0.04
    property real honeycombCenterX: 0.5
    property real honeycombCenterY: 0.5

    readonly property real edgeSmoothness: Settings.data.wallpaper.transitionEdgeSmoothness
    readonly property vector4d fillColor: Qt.vector4d(0, 0, 0, 1)

    function _pathStr(p) {
      var s = p.toString();
      return s.startsWith("file://") ? s.substring(7) : s;
    }

    function _pickTransition() {
      var selected = Settings.data.wallpaper.transitionType;
      transitionType = (!selected || selected.length === 0) ? "fade" : selected[Math.floor(Math.random() * selected.length)];
      if (root.allTransitions.indexOf(transitionType) === -1)
        transitionType = "fade";
      switch (transitionType) {
      case "wipe":
        wipeDirection = Math.floor(Math.random() * 4);
        break;
      case "disc":
        discCenterX = Math.random();
        discCenterY = Math.random();
        break;
      case "stripes":
        stripesCount = Math.round(Math.random() * 20 + 4);
        stripesAngle = Math.random() * 360;
        break;
      case "pixelate":
        pixelateMaxBlockSize = Math.round(Math.random() * 80 + 32);
        break;
      case "honeycomb":
        honeycombCellSize = Math.random() * 0.04 + 0.02;
        honeycombCenterX = Math.random();
        honeycombCenterY = Math.random();
        break;
      }
    }

    onTargetUrlChanged: {
      // Not yet initialized: show it directly, no transition (see notes.md
      // for why this branch must assign rather than bail).
      if (!root.initialized) {
        currentWallpaper.source = targetUrl;
        return;
      }
      if (root._pathStr(targetUrl) === root._pathStr(currentWallpaper.source))
        return;
      if (transitionAnimation.running) {
        transitionAnimation.stop();
        currentWallpaper.source = nextWallpaper.source;
        root.transitionProgress = 0;
      }
      root._pickTransition();
      nextWallpaper.source = targetUrl;
    }

    Component.onCompleted: {
      if (root.targetUrl)
        currentWallpaper.source = root.targetUrl;
    }

    Image {
      id: currentWallpaper
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: true
      visible: false
      onStatusChanged: if (status === Image.Ready && !root.initialized)
        root.initialized = true
    }

    Image {
      id: nextWallpaper
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      visible: false
      onStatusChanged: if (status === Image.Ready)
        transitionAnimation.start()
    }

    Loader {
      id: shaderLoader
      anchors.fill: parent
      sourceComponent: {
        switch (root.transitionType) {
        case "wipe":
          return wipeComponent;
        case "disc":
          return discComponent;
        case "stripes":
          return stripesComponent;
        case "pixelate":
          return pixelateComponent;
        case "honeycomb":
          return honeycombComponent;
        default:
          return fadeComponent;
        }
      }
    }

    Component {
      id: fadeComponent
      ShaderEffect {
        anchors.fill: parent
        property variant source1: currentWallpaper
        property variant source2: nextWallpaper.status === Image.Ready ? nextWallpaper : currentWallpaper
        property real progress: root.transitionProgress
        property real fillMode: 1.0
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height
        property real isSolid1: 0.0
        property real isSolid2: 0.0
        property vector4d solidColor1: root.fillColor
        property vector4d solidColor2: root.fillColor
        fragmentShader: Qt.resolvedUrl(root.shaderDir + "wp_fade.frag.qsb")
      }
    }

    Component {
      id: wipeComponent
      ShaderEffect {
        anchors.fill: parent
        property variant source1: currentWallpaper
        property variant source2: nextWallpaper.status === Image.Ready ? nextWallpaper : currentWallpaper
        property real progress: root.transitionProgress
        property real smoothness: root.edgeSmoothness
        property real direction: root.wipeDirection
        property real fillMode: 1.0
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height
        property real isSolid1: 0.0
        property real isSolid2: 0.0
        property vector4d solidColor1: root.fillColor
        property vector4d solidColor2: root.fillColor
        fragmentShader: Qt.resolvedUrl(root.shaderDir + "wp_wipe.frag.qsb")
      }
    }

    Component {
      id: discComponent
      ShaderEffect {
        anchors.fill: parent
        property variant source1: currentWallpaper
        property variant source2: nextWallpaper.status === Image.Ready ? nextWallpaper : currentWallpaper
        property real progress: root.transitionProgress
        property real smoothness: root.edgeSmoothness
        property real aspectRatio: root.width / root.height
        property real centerX: root.discCenterX
        property real centerY: root.discCenterY
        property real fillMode: 1.0
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height
        property real isSolid1: 0.0
        property real isSolid2: 0.0
        property vector4d solidColor1: root.fillColor
        property vector4d solidColor2: root.fillColor
        fragmentShader: Qt.resolvedUrl(root.shaderDir + "wp_disc.frag.qsb")
      }
    }

    Component {
      id: stripesComponent
      ShaderEffect {
        anchors.fill: parent
        property variant source1: currentWallpaper
        property variant source2: nextWallpaper.status === Image.Ready ? nextWallpaper : currentWallpaper
        property real progress: root.transitionProgress
        property real smoothness: root.edgeSmoothness
        property real aspectRatio: root.width / root.height
        property real stripeCount: root.stripesCount
        property real angle: root.stripesAngle
        property real fillMode: 1.0
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height
        property real isSolid1: 0.0
        property real isSolid2: 0.0
        property vector4d solidColor1: root.fillColor
        property vector4d solidColor2: root.fillColor
        fragmentShader: Qt.resolvedUrl(root.shaderDir + "wp_stripes.frag.qsb")
      }
    }

    Component {
      id: pixelateComponent
      ShaderEffect {
        anchors.fill: parent
        property variant source1: currentWallpaper
        property variant source2: nextWallpaper.status === Image.Ready ? nextWallpaper : currentWallpaper
        property real progress: root.transitionProgress
        property real maxBlockSize: root.pixelateMaxBlockSize
        property real fillMode: 1.0
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height
        property real isSolid1: 0.0
        property real isSolid2: 0.0
        property vector4d solidColor1: root.fillColor
        property vector4d solidColor2: root.fillColor
        fragmentShader: Qt.resolvedUrl(root.shaderDir + "wp_pixelate.frag.qsb")
      }
    }

    Component {
      id: honeycombComponent
      ShaderEffect {
        anchors.fill: parent
        property variant source1: currentWallpaper
        property variant source2: nextWallpaper.status === Image.Ready ? nextWallpaper : currentWallpaper
        property real progress: root.transitionProgress
        property real cellSize: root.honeycombCellSize
        property real centerX: root.honeycombCenterX
        property real centerY: root.honeycombCenterY
        property real aspectRatio: root.width / root.height
        property real fillMode: 1.0
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height
        property real isSolid1: 0.0
        property real isSolid2: 0.0
        property vector4d solidColor1: root.fillColor
        property vector4d solidColor2: root.fillColor
        fragmentShader: Qt.resolvedUrl(root.shaderDir + "wp_honeycomb.frag.qsb")
      }
    }

    NumberAnimation {
      id: transitionAnimation
      target: root
      property: "transitionProgress"
      from: 0.0
      to: 1.0
      duration: Settings.data.wallpaper.transitionDuration
      easing.type: Easing.InOutCubic
      onFinished: {
        currentWallpaper.source = nextWallpaper.source;
        root.transitionProgress = 0;
        Qt.callLater(function () {
          nextWallpaper.source = "";
        });
      }
    }
  }
}
