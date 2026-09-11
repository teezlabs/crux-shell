import Quickshell.Io

// Volume step, overdrive and the preferred MPRIS player.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property real step: 0.05 // volume change per scroll notch / hardware key press
    // Lets scroll/hardware-key volume changes go past 100% (up to 150%)
    // instead of hard-capping at 1.0. Doesn't touch the popups' own
    // drag-slider ceiling (SegMeter.qml is a shared 0-100 component used
    // by Sound/Microphone/ControlCenter -- rescaling it is a bigger,
    // separate change), so overdriving past 100% still needs scroll or
    // the hardware keys, not the slider itself.
    property bool volumeOverdrive: false
    // MPRIS player.identity to prefer as "active" over the default
    // "Playing, else first" pick. "" = auto. Matched independently in
    // Media.qml, MediaPlayerPopupContent.qml, ControlCenterPopupContent.qml.
    property string preferredMediaPlayer: ""
}
