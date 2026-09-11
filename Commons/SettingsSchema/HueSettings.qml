import Quickshell.Io

// Philips Hue bridge connection.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property string bridgeIp: ""
    property string username: ""
    property string selectedGroupId: ""
    property string selectedGroupName: ""
}
