import Quickshell.Io

// wlsunset schedule, or sun position when location is on.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property bool enabled: false
    property bool forced: false // bypass the sunset/sunrise schedule, always-on
    property int nightTemp: 4000 // Kelvin
    property int dayTemp: 6500 // Kelvin, wlsunset's "no filter" value
    property string manualSunset: "19:00"
    property string manualSunrise: "06:00"
    // Real sunrise/sunset via wlsunset's own -l/-L sun-position math,
    // fed the same IP-geolocated lat/lon Commons/Weather.qml already
    // fetches for the Control Center weather card — falls back to the
    // manual schedule above if geolocation hasn't resolved yet.
    property bool useLocation: false
}
