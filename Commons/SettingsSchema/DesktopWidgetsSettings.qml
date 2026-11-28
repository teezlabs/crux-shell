import Quickshell.Io

// Desktop-layer widget settings.
JsonObject {
  property bool enabled: true // the cards pinned to the desktop layer
  property bool weatherEnabled: true
  property bool mediaEnabled: true
  property bool clockEnabled: false
  // Edit mode snaps cards (position and size) to the on-screen grid.
  property bool gridSnap: true

  // Clock card: Qt date/time formats; an empty date format hides the date line.
  property string clockFormat: "HH:mm"
  property string clockDateFormat: "ddd  yyyy-MM-dd"

  // The output each card lives on; "" = the first screen. Cards aren't mirrored across monitors.
  property string weatherScreen: ""
  property string mediaScreen: ""
  property string clockScreen: ""

  // Card background behind each widget; off draws it straight on the wallpaper.
  property bool weatherCard: true
  property bool mediaCard: true
  property bool clockCard: true

  // -1 = not placed yet; the widget uses its default corner until dragged.
  property real weatherX: -1
  property real weatherY: -1
  property real mediaX: -1
  property real mediaY: -1
  property real clockX: -1
  property real clockY: -1

  // Size multiplier set by the edit-mode resize handle.
  property real weatherScale: 1
  property real mediaScale: 1
  property real clockScale: 1
}
