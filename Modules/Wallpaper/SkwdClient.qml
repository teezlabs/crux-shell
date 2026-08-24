pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Minimal fresh client for skwd-daemon's own line-delimited JSON-RPC socket
// protocol (one JSON object + "\n" per request/response, plus unsolicited
// {"event": ..., "data": ...} push messages) — written from scratch against
// the live daemon's actual responses, not ported from noctalia's own
// DaemonClient.qml. Only exposes what crux's wallpaper picker needs:
// listing wallpapers and applying one. skwd-daemon itself still owns the
// real wallpaper library (thumbnails, favourites, indexing) — crux just
// talks to it, the way any other skwd client would.
Singleton {
  id: client

  readonly property bool connected: socket.connected

  signal wallpaperApplied(string path)
  signal listChanged

  property int _nextId: 1
  property var _pending: ({})

  function call(method, params, callback) {
    if (!socket.connected) {
      if (callback)
        callback(null, {
          "message": "not connected"
        });
      return;
    }
    var id = _nextId++;
    if (callback)
      _pending[id] = callback;
    var line = JSON.stringify({
      "method": method,
      "params": params || {},
      "id": id
    });
    socket.write(line + "\n");
    socket.flush();
  }

  // callback(wallpapers, error) — wallpapers: [{key, name, thumb, thumb_sm, favourite, type, ...}]
  function listWallpapers(callback) {
    call("wall.list", {
      "favourites": false
    }, function (result, error) {
      if (callback)
        callback(result && result.wallpapers ? result.wallpapers : [], error);
    });
  }

  function applyStatic(path) {
    call("wall.apply", {
      "type": "static",
      "path": path
    });
  }

  function _handleLine(line) {
    line = line.trim();
    if (!line)
      return;
    var msg;
    try {
      msg = JSON.parse(line);
    } catch (e) {
      return;
    }
    if (msg.event) {
      _handleEvent(msg.event, msg.data || {});
      return;
    }
    if (msg.id !== undefined && _pending[msg.id]) {
      var cb = _pending[msg.id];
      delete _pending[msg.id];
      cb(msg.result, msg.error || null);
    }
  }

  function _handleEvent(event, data) {
    switch (event) {
    case "skwd.wall.applied":
      client.wallpaperApplied(data.path || "");
      break;
    case "skwd.wall.file_added":
    case "skwd.wall.file_removed":
    case "skwd.wall.file_renamed":
    case "skwd.wall.folder_removed":
      client.listChanged();
      break;
    }
  }

  Socket {
    id: socket
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/skwd/daemon.sock"
    connected: false

    parser: SplitParser {
      onRead: data => client._handleLine(data)
    }

    onConnectionStateChanged: {
      if (connected) {
        client.call("subscribe", {
          "events": ["skwd."]
        });
      } else {
        client._pending = ({});
        reconnectTimer.restart();
      }
    }
  }

  Timer {
    id: reconnectTimer
    interval: 2000
    repeat: false
    onTriggered: if (!socket.connected)
      socket.connected = true
  }

  Component.onCompleted: socket.connected = true
}
