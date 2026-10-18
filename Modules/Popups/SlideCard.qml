import QtQuick
import qs.Commons
import qs.Widgets

// Pins a popup flush to the bar's edge and collapses it into the bar on close (docs/design-notes.md, "Slide-to-close").
Item {
  id: root

  required property var host // PopupHost's own PanelWindow — gives host.width/height to position against (not an Item, so untyped)
  property string barPos: "top" // "top" | "bottom" | "left" | "right"
  // Named shown, not open, so open()/close()/toggle() can be functions, as in every Popups surface.
  property bool shown: false
  // Card name; PopupIpc derives "<name>" and "<name>_<screen>" from it.
  property string popupName: ""
  // Inset applied to the content layer on all four sides.
  property real contentMargins: Tokens.spaceXl
  property real cardWidth: 300
  property real cardHeight: 200
  // Position along the bar; lines up with the triggering icon when set, centred otherwise.
  property real crossPos: (root.barLeft || root.barRight) ? (root.host.height - root.cardHeight) / 2 : (root.host.width - root.cardWidth) / 2

  readonly property bool barLeft: root.barPos === "left"
  readonly property bool barRight: root.barPos === "right"
  readonly property bool barBottom: root.barPos === "bottom"
  readonly property bool barTop: !root.barLeft && !root.barRight && !root.barBottom

  // Docked strip: the card overlaps the bar's inner edge line so the two outlines join.
  readonly property bool joined: Tokens.barDocked || Tokens.barPill
  // Floating (or no strip): the card stands off the bar by the bar's own margin, fully outlined.
  readonly property real barOffset: Tokens.barExtent + (root.joined ? -Tokens.borderPanel : Tokens.barMargin)
  // Keeps the card within a floating bar's ends.
  readonly property real crossInset: Math.max(8, Tokens.barMargin)

  default property alias content: contentLayer.data

  function toggle() {
    root.shown = !root.shown;
  }

  function open() {
    root.shown = true;
  }

  function close() {
    root.shown = false;
  }

  // Opens aligned to (x, y), clamped on screen; a second call closes.
  function openAt(x, y) {
    if (root.shown) {
      root.shown = false;
      return;
    }
    // Bar widgets map into the bar window, which a floating bar insets by its margin.
    const anchor = ((root.barLeft || root.barRight) ? y : x) + Tokens.barMargin;
    // A binding, so content that fills in after opening re-clamps the card.
    root.crossPos = Qt.binding(() => root._clampCross(anchor));
    root.shown = true;
  }

  // Morph mode: also collapses along the bar to the triggering module's size. -1 disables.
  property real morphExtent: -1
  property real morphCross: 0
  // Morph even on a docked strip; otherwise only a detached bar morphs.
  property bool alwaysMorph: false
  property bool _snap: false
  readonly property bool morphing: root.morphExtent >= 0 && (root.alwaysMorph || Tokens.barFloating)

  // Pushed as soon as the module is laid out, so the closed card already rests folded into it.
  function setMorphSource(x, y, w, h) {
    const vertical = root.barLeft || root.barRight;
    root.morphExtent = vertical ? h : w;
    root.morphCross = (vertical ? y : x) + Tokens.barMargin;
    if (!root.shown && root.morphing)
      root.crossPos = root.morphCross;
  }

  // The pill cuts top-right and bottom-left; where that cut lands on the joining side, stop short of it.
  readonly property real _startCut: Tokens.barPill && (root.barTop || root.barLeft) ? Tokens.chamferBarFloating : 0
  readonly property real _endCut: Tokens.barPill && (root.barBottom || root.barRight) ? Tokens.chamferBarFloating : 0

  function _clampCross(v) {
    const lo = root.crossInset + root._startCut;
    const hi = (root.barLeft || root.barRight) ? root.host.height - root.cardHeight - root.crossInset - root._endCut : root.host.width - root.cardWidth - root.crossInset - root._endCut;
    return Math.max(lo, Math.min(v, hi));
  }

  // Centred on the module it unfolds from.
  function _openCross() {
    const size = (root.barLeft || root.barRight) ? root.cardHeight : root.cardWidth;
    return root._clampCross(root.morphCross + root.morphExtent / 2 - size / 2);
  }

  // Opens out of the module at (x, y, w, h): morphs when detached, otherwise like openAt. Toggles.
  function openFrom(x, y, w, h) {
    if (root.shown) {
      root.shown = false;
      return;
    }
    // Fold onto the module instantly first; a card never tapped before rests at full width.
    root._snap = true;
    root.setMorphSource(x, y, w, h);
    if (root.morphing)
      root.crossPos = root.morphCross;
    root._snap = false;
    if (!root.morphing) {
      root.openAt(x, y);
      return;
    }
    root.shown = true;
  }

  onShownChanged: {
    if (root.morphing)
      root.crossPos = root.shown ? Qt.binding(() => root._openCross()) : root.morphCross;
  }

  // Travel axis collapses to 0; the cross axis keeps full size unless morphing.
  readonly property real _crossClosed: root.morphing ? root.morphExtent : -1
  readonly property real _animWidth: (root.barLeft || root.barRight) ? (root.shown ? root.cardWidth : 0) : (root.shown || !root.morphing ? root.cardWidth : root._crossClosed)
  readonly property real _animHeight: (root.barTop || root.barBottom) ? (root.shown ? root.cardHeight : 0) : (root.shown || !root.morphing ? root.cardHeight : root._crossClosed)

  width: _animWidth
  height: _animHeight
  // The clip that hides the collapsing content lives on `body`.
  clip: false

  Behavior on width {
    enabled: !root._snap
    NumberAnimation {
      duration: Tokens.durationSidebarSlide
      easing.type: Tokens.easingSidebarSlide
    }
  }
  Behavior on height {
    enabled: !root._snap
    NumberAnimation {
      duration: Tokens.durationSidebarSlide
      easing.type: Tokens.easingSidebarSlide
    }
  }
  Behavior on crossPos {
    enabled: root.morphing && !root._snap
    NumberAnimation {
      duration: Tokens.durationSidebarSlide
      easing.type: Tokens.easingSidebarSlide
    }
  }

  // The bar-facing edge stays pinned, so the card grows out of the bar.
  x: root.barLeft ? root.barOffset : (root.barRight ? root.host.width - root.barOffset - root.width : root.crossPos)
  y: root.barBottom ? root.host.height - root.barOffset - root.height : (root.barLeft || root.barRight ? root.crossPos : root.barOffset)

  Item {
    id: body
    anchors.fill: parent
    clip: true

  Chamfer {
    // Morph mode draws the outline at the animating size; otherwise full size, clipped.
    width: root.morphing ? root.width : root.cardWidth
    height: root.morphing ? root.height : root.cardHeight
    // Drawn at full size from the fixed corner and clipped, so the chamfer never stretches.
    x: root.barRight ? root.width - root.cardWidth : 0
    y: root.barBottom ? root.height - root.cardHeight : 0
    chamferSize: Tokens.chamferPanel
    // Cut only the far corners and skip the bar-side stroke, so the card grows out of the bar.
    cutTopLeft: root.barBottom || root.barRight
    cutTopRight: root.barBottom || root.barLeft
    cutBottomLeft: root.barTop || root.barRight
    cutBottomRight: root.barTop || root.barLeft
    omitStrokeSide: !root.joined ? "" : (root.barBottom ? "bottom" : (root.barLeft ? "left" : (root.barRight ? "right" : "top")))
    fillColor: root.joined ? Colors.alpha(Colors.barSurface, Settings.data.bar.barBackgroundOpacity) : Colors.alpha(Colors.surface, Tokens.panelOpacity)
    strokeColor: Colors.outline
    strokeWidth: Tokens.borderPanel
    // Rim only: body clips for the collapse, which would cut a shadow off at the edge.
    rimLight: root.barLeft || root.barRight
  }

  // Keeps clicks on the card from reaching the host's click-outside handler.
  MouseArea {
    width: root.cardWidth
    height: root.cardHeight
    x: root.barRight ? root.width - root.cardWidth : 0
    y: root.barBottom ? root.height - root.cardHeight : 0
    onClicked: {}
  }

  Item {
    id: contentLayer
    width: root.cardWidth - root.contentMargins * 2
    height: root.cardHeight - root.contentMargins * 2
    x: (root.barRight ? root.width - root.cardWidth : 0) + root.contentMargins
    y: (root.barBottom ? root.height - root.cardHeight : 0) + root.contentMargins
    // The content can't morph with the frame, so it fades in behind it.
    opacity: root.morphing && !root.shown ? 0 : 1
    Behavior on opacity {
      NumberAnimation {
        duration: Tokens.durationSidebarSlide
        easing.type: Tokens.easingSidebarSlide
      }
    }
  }

  }
}
