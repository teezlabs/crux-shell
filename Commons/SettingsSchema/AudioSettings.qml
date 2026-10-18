import Quickshell.Io

// Volume step, overdrive and the preferred MPRIS player.
JsonObject {
    property real step: 0.05 // volume change per scroll notch / hardware key press
    // Scroll and hardware keys may go past 100% (to 150%); the popup sliders still stop at 100%.
    property bool volumeOverdrive: false
    // MPRIS identity MediaService prefers over "playing, else first". "" = auto.
    property string preferredMediaPlayer: ""
}
