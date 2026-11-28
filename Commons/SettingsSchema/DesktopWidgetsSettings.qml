import Quickshell.Io

// Desktop-layer widget settings.
JsonObject {
  property bool enabled: true // weather + now-playing cards pinned to the desktop layer
  property bool weatherEnabled: true
  property bool mediaEnabled: true
  property bool controlCenterEnabled: false
  // Output name for the Control Center card; "" = the first screen.
  property string controlCenterScreen: ""

  // -1 = not placed yet; the widget uses its default corner until dragged.
  property real weatherX: -1
  property real weatherY: -1
  property real mediaX: -1
  property real mediaY: -1
  property real controlCenterX: -1
  property real controlCenterY: -1
}
