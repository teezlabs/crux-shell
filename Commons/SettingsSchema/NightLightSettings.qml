import Quickshell.Io

// wlsunset schedule, or sun position when location is on.
JsonObject {
    property bool enabled: false
    property bool forced: false // bypass the sunset/sunrise schedule, always-on
    property int nightTemp: 4000 // Kelvin
    property int dayTemp: 6500 // Kelvin, wlsunset's "no filter" value
    property string manualSunset: "19:00"
    property string manualSunrise: "06:00"
    // Use wlsunset's sun-position mode with Services/Weather.qml's geolocation; the manual schedule is the fallback.
    property bool useLocation: false
}
