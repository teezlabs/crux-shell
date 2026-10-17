import QtQuick
import qs.Commons
import qs.Widgets

// Positions a popup's content flush against whichever edge the bar sits
// on, and collapses it toward that edge on close instead of the window
// just appearing/disappearing — see crux skill's notes.md for why this
// replaced one-PanelWindow-per-popup (each popup used to unmap instantly
// on close, so only the open direction could ever animate).
//
// Shrinks size rather than translating position off-screen: PopupHost
// sits on WlrLayer.Overlay, above the bar's own WlrLayer.Top, so a card
// sliding *past* the bar on its way off-screen always renders on top of
// it, never behind — it reads as flying past the bar, not retracting
// into it (confirmed live). Collapsing the axis-of-travel dimension back
// to 0 at the bar-facing edge instead gives a genuine "absorbed into the
// bar" look with no layering trick needed.
Item {
  id: root

  required property var host // PopupHost's own PanelWindow — gives host.width/height to position against (not an Item, so untyped)
  property string barPos: "top" // "top" | "bottom" | "left" | "right"
  // Named `shown`, not `open`, so open()/close()/toggle() can be real
  // functions — every surface in the Popups registry implements the same
  // contract.
  property bool shown: false
  // Identifies this card to PopupIpc, which derives its IPC target names
  // from it ("wifi" -> "wifi" and "wifi_<screen>").
  property string popupName: ""
  // Inset applied to the content layer on all four sides.
  property real contentMargins: Tokens.spaceXl
  property real cardWidth: 300
  property real cardHeight: 200
  // Cross-axis position (along the bar's own length) — lines up with a
  // triggering bar icon when the caller sets it, defaults centered.
  property real crossPos: (root.barLeft || root.barRight) ? (root.host.height - root.cardHeight) / 2 : (root.host.width - root.cardWidth) / 2

  readonly property bool barLeft: root.barPos === "left"
  readonly property bool barRight: root.barPos === "right"
  readonly property bool barBottom: root.barPos === "bottom"
  readonly property bool barTop: !root.barLeft && !root.barRight && !root.barBottom

  // Docked strip: the card overlaps the bar's inner edge line so the two outlines join.
  readonly property bool joined: Tokens.barDocked
  readonly property real barOffset: Tokens.barExtent - (root.joined ? Tokens.borderPanel : 0)

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

  // Opens lined up with the bar icon at (x, y), clamped to stay on
  // screen. A second call while open closes instead, so one bar-icon tap
  // handler covers both directions.
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

  // Morph mode: the card also collapses along the bar (to `morphExtent`,
  // sitting at `morphCross`) instead of only away from it, so it reads as
  // the triggering bar module itself unfolding into the panel. -1 disables.
  property real morphExtent: -1
  property real morphCross: 0
  property real openCross: 0
  readonly property bool morphing: root.morphExtent >= 0

  // Morph geometry is pushed by the triggering bar module as soon as it is
  // laid out, not on the tap: a closed card holds its full cross-axis size,
  // so learning the collapsed size only at open time means animating down
  // and back up again, and it never folds into the module at all. Set ahead
  // of time, the card simply rests folded — invisible either way, since a
  // closed card is fully collapsed away from the bar.
  function setMorphSource(x, y, w, h) {
    const vertical = root.barLeft || root.barRight;
    root.morphExtent = vertical ? h : w;
    root.morphCross = (vertical ? y : x) + Tokens.barMargin;
    if (!root.shown)
      root.crossPos = root.morphCross;
    // Keeps a plain open() (IPC, a keybind) landing in the same place a tap
    // would, instead of at the default cross position.
    root.openCross = root._clampCross(root.morphCross);
  }

  function _clampCross(v) {
    return (root.barLeft || root.barRight) ? Math.max(8, Math.min(v, root.host.height - root.cardHeight - 8)) : Math.max(8, Math.min(v, root.host.width - root.cardWidth - 8));
  }

  // Morph-mode entry point. Toggles closed if already open, like openAt.
  function openFrom(x, y, w, h) {
    if (root.shown) {
      root.shown = false;
      return;
    }
    root.setMorphSource(x, y, w, h);
    root.shown = true;
  }

  onShownChanged: {
    if (root.morphing)
      root.crossPos = root.shown ? root.openCross : root.morphCross;
  }

  // The axis of travel away from the bar collapses to 0 on close; the
  // cross axis (along the bar's own length) holds its full size, unless
  // morph mode shrinks it back to the bar module it came from.
  readonly property real _crossClosed: root.morphing ? root.morphExtent : -1
  readonly property real _animWidth: (root.barLeft || root.barRight) ? (root.shown ? root.cardWidth : 0) : (root.shown || !root.morphing ? root.cardWidth : root._crossClosed)
  readonly property real _animHeight: (root.barTop || root.barBottom) ? (root.shown ? root.cardHeight : 0) : (root.shown || !root.morphing ? root.cardHeight : root._crossClosed)

  width: _animWidth
  height: _animHeight
  // The clip that hides the collapsing content lives on `body`.
  clip: false

  Behavior on width {
    NumberAnimation {
      duration: Tokens.durationSidebarSlide
      easing.type: Tokens.easingSidebarSlide
    }
  }
  Behavior on height {
    NumberAnimation {
      duration: Tokens.durationSidebarSlide
      easing.type: Tokens.easingSidebarSlide
    }
  }
  Behavior on crossPos {
    enabled: root.morphing
    NumberAnimation {
      duration: Tokens.durationSidebarSlide
      easing.type: Tokens.easingSidebarSlide
    }
  }

  // The edge touching the bar stays pinned; the far edge is what moves as
  // width/height animate, so the card visibly grows from (or shrinks
  // back into) the bar's own edge rather than growing from its center.
  x: root.barLeft ? root.barOffset : (root.barRight ? root.host.width - root.barOffset - root.width : root.crossPos)
  y: root.barBottom ? root.host.height - root.barOffset - root.height : (root.barLeft || root.barRight ? root.crossPos : root.barOffset)

  Item {
    id: body
    anchors.fill: parent
    clip: true

  Chamfer {
    // Morph mode draws the outline at the animating size so the panel
    // visibly unfolds; otherwise it stays full-size and is simply clipped.
    width: root.morphing ? root.width : root.cardWidth
    height: root.morphing ? root.height : root.cardHeight
    // Anchored to whichever corner of the shrinking Item stays fixed
    // (the bar-facing edge), so the chamfered background doesn't itself
    // stretch/squash during the collapse — it's always drawn at full
    // size, just increasingly clipped by the parent Item's clip:true as
    // width/height shrink toward the bar.
    x: root.barRight ? root.width - root.cardWidth : 0
    y: root.barBottom ? root.height - root.cardHeight : 0
    chamferSize: Tokens.chamferPanel
    // Flush against the bar, so cut only the two corners on the far side
    // from it, and skip the stroke on the near side entirely — the card
    // reads as growing out of the bar instead of floating as a fully
    // separate bordered card.
    cutTopLeft: root.barBottom || root.barRight
    cutTopRight: root.barBottom || root.barLeft
    cutBottomLeft: root.barTop || root.barRight
    cutBottomRight: root.barTop || root.barLeft
    omitStrokeSide: root.barBottom ? "bottom" : (root.barLeft ? "left" : (root.barRight ? "right" : "top"))
    fillColor: Colors.alpha(Colors.surface, root.joined ? Settings.data.bar.barBackgroundOpacity : Tokens.panelOpacity)
    strokeColor: Colors.outline
    strokeWidth: Tokens.borderPanel
    // Rim only, no shadow: `body` clips for the collapse animation, so a
    // shadow would be cut off flush at the card's own edge.
    rimLight: root.barLeft || root.barRight
  }

  // Swallow clicks on the card itself so they don't fall through to the
  // host's own full-surface click-outside-to-close MouseArea underneath.
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
