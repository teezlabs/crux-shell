import Quickshell.Io

// Desktop-layer widget settings. Split out of Settings.qml's schema; the
// JsonAdapter serializes this exactly as it did when the block was inline.
JsonObject {
  property bool enabled: true // weather + now-playing cards pinned to the desktop layer
  property bool weatherEnabled: true
  property bool mediaEnabled: true

  // -1 means "not placed yet"; the widget falls back to its default corner
  // until the user drags it somewhere.
  property real weatherX: -1
  property real weatherY: -1
  property real mediaX: -1
  property real mediaY: -1
}
