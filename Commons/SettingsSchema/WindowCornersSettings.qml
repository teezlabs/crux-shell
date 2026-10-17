import Quickshell.Io

// Which corners Hyprland windows cut, applied by Services/WindowCorners.qml.
JsonObject {
    property bool enabled: true
    property bool cutTopLeft: false
    property bool cutTopRight: true
    property bool cutBottomRight: false
    property bool cutBottomLeft: true
}
