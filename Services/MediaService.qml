pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons

// The MPRIS player every media surface shows: the preferred one, else the first playing, else the first.
Singleton {
  id: root

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: {
    var preferred = Settings.isLoaded ? Settings.data.audio.preferredMediaPlayer : "";
    return (preferred && players.find(p => p && p.identity === preferred)) || players.find(p => p && p.playbackState === MprisPlaybackState.Playing) || players[0] || null;
  }
  readonly property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false

  // MPRIS doesn't reliably emit positionChanged during playback; the tick re-evaluates position every second.
  property int _positionTick: 0
  readonly property real position: {
    _positionTick;
    return activePlayer ? activePlayer.position : 0;
  }
  readonly property real length: activePlayer ? activePlayer.length : 0

  function fmtTime(seconds: real): string {
    if (!seconds || seconds < 0)
      return "0:00";
    var m = Math.floor(seconds / 60);
    var s = Math.floor(seconds % 60);
    return m + ":" + String(s).padStart(2, "0");
  }

  readonly property Timer positionTimer: Timer {
    interval: 1000
    running: root.isPlaying
    repeat: true
    onTriggered: root._positionTick++
  }
}
