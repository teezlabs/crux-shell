pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// wallhaven.cc search. No API key is needed for SFW toplist search; one is
// only required for NSFW results and for a user's own collections, and the
// key comes from the wallpaper settings when set.
//
// Shared rather than per-window: only one browser is ever in use at a time,
// and keeping the results here means reopening it doesn't re-fetch.
Singleton {
  id: root

  // Wallhaven blocks the default curl agent.
  readonly property string _userAgent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

  // [{id, path (full-res url), thumb, name, ext, isRemote: true}]
  property var results: []
  property bool loading: false
  property string error: ""
  // toplist | date_added | views | favorites
  property string sorting: "toplist"
  property int page: 1
  property int lastPage: 1

  // Set by the caller before searching.
  property string query: ""

  signal resultsReplaced

  readonly property string _purity: (Settings.data.wallpaper.wallhavenSfw ? "1" : "0") + (Settings.data.wallpaper.wallhavenSketchy ? "1" : "0") + (Settings.data.wallpaper.wallhavenNsfw ? "1" : "0")

  function _buildUrl(page) {
    var url = "https://wallhaven.cc/api/v1/search?categories=111&purity=" + root._purity + "&";
    if (root.query)
      url += "q=" + encodeURIComponent(root.query) + "&";
    url += "sorting=" + root.sorting + "&order=desc&";
    if (root.sorting === "toplist")
      url += "topRange=1M&";
    if (Settings.data.wallpaper.wallhavenApiKey)
      url += "apikey=" + encodeURIComponent(Settings.data.wallpaper.wallhavenApiKey) + "&";
    if (Settings.data.wallpaper.wallhavenAtLeast)
      url += "atleast=" + Settings.data.wallpaper.wallhavenAtLeast + "&";
    if (Settings.data.wallpaper.wallhavenRatio)
      url += "ratios=" + Settings.data.wallpaper.wallhavenRatio + "&";
    url += "page=" + page;
    return url;
  }

  // `append` adds to the current results instead of replacing them, for
  // paging further down the same search.
  function search(page, append) {
    if (root.loading)
      return;
    root.loading = true;
    root.error = "";
    root.page = page || 1;
    searchProc.append = !!append;
    searchProc.command = ["curl", "-fsSL", "-A", root._userAgent, root._buildUrl(root.page)];
    searchProc.running = true;
  }

  readonly property Process searchProc: Process {
    id: searchProc
    property bool append: false
    stdout: StdioCollector {
      id: searchCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      root.loading = false;
      if (exitCode !== 0) {
        root.error = "Network error (curl exit " + exitCode + ")";
        return;
      }
      try {
        var json = JSON.parse(searchCollector.text);
        if (json.error) {
          root.error = json.error;
          return;
        }
        var items = (json.data || []).map(item => {
          var ext = item.path.split(".").pop().split("?")[0].toLowerCase();
          return {
            "id": item.id,
            "path": item.path,
            "thumb": item.thumbs ? item.thumbs.large : item.path,
            "name": "wallhaven-" + item.id + "." + ext,
            "ext": ext,
            "isRemote": true
          };
        });
        root.results = searchProc.append ? root.results.concat(items) : items;
        root.lastPage = json.meta && json.meta.last_page ? json.meta.last_page : 1;
        if (!searchProc.append)
          root.resultsReplaced();
      } catch (e) {
        root.error = "Parse error: " + e.message;
      }
    }
  }
}
