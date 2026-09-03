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
  property bool open: false
  // Identifies this card to PopupIpc, which derives its IPC target names
  // from it ("wifi" -> "wifi" and "wifi_<screen>").
  property string popupName: ""
  // Inset applied to the content layer on all four sides.
  property real contentMargins: 14
  property real cardWidth: 300
  property real cardHeight: 200
  // Cross-axis position (along the bar's own length) — lines up with a
  // triggering bar icon when the caller sets it, defaults centered.
  property real crossPos: (root.barLeft || root.barRight) ? (root.host.height - root.cardHeight) / 2 : (root.host.width - root.cardWidth) / 2

  readonly property bool barLeft: root.barPos === "left"
  readonly property bool barRight: root.barPos === "right"
  readonly property bool barBottom: root.barPos === "bottom"
  readonly property bool barTop: !root.barLeft && !root.barRight && !root.barBottom

  // Flush against the bar's own outer edge, same offset the old
  // per-popup _barOffset used.
  readonly property real barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin

  default property alias content: contentLayer.data

  function toggle() {
    root.open = !root.open;
  }

  // Opens lined up with the bar icon at (x, y), clamped to stay on
  // screen. A second call while open closes instead, so one bar-icon tap
  // handler covers both directions.
  function openAt(x, y) {
    if (root.open) {
      root.open = false;
      return;
    }
    const vertical = root.barLeft || root.barRight;
    root.crossPos = vertical ? Math.max(8, Math.min(y, root.host.height - root.cardHeight - 8)) : Math.max(8, Math.min(x, root.host.width - root.cardWidth - 8));
    root.open = true;
  }

  // The axis of travel away from the bar collapses to 0 on close; the
  // cross axis (along the bar's own length) stays fixed at its full size
  // the whole time.
  readonly property real _animWidth: (root.barLeft || root.barRight) ? (root.open ? root.cardWidth : 0) : root.cardWidth
  readonly property real _animHeight: (root.barTop || root.barBottom) ? (root.open ? root.cardHeight : 0) : root.cardHeight

  width: _animWidth
  height: _animHeight
  clip: true

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

  // The edge touching the bar stays pinned; the far edge is what moves as
  // width/height animate, so the card visibly grows from (or shrinks
  // back into) the bar's own edge rather than growing from its center.
  x: root.barLeft ? root.barOffset : (root.barRight ? root.host.width - root.barOffset - root.width : root.crossPos)
  y: root.barBottom ? root.host.height - root.barOffset - root.height : (root.barLeft || root.barRight ? root.crossPos : root.barOffset)

  Chamfer {
    width: root.cardWidth
    height: root.cardHeight
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
    fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
    strokeColor: Color.outline
    strokeWidth: Tokens.borderPanel
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
  }
}
