import Quickshell.Io

// Local plugin discovery.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property list<var> sources: [] // [{ "url": "...", "name": "...", "enabled": true }]
}
