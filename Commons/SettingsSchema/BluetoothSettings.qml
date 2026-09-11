import Quickshell.Io

// Bluetooth widget behavior.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    // Was hardcoded true in BluetoothModel.js's deviceLists() -- a
    // device that hasn't announced a real name yet (mid-pairing, some
    // odd peripherals) is invisible while this is on.
    property bool hideUnnamedDevices: true
}
