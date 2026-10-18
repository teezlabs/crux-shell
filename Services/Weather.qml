pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Weather from ip-api.com geolocation and open-meteo (keyless), fetched with curl.
Singleton {
  id: root

  property string cityName: ""
  // Despite the name, in whatever unit controlCenter.tempUnit asked for; display with unitSuffix.
  property real currentTempF: NaN
  property int currentWeatherCode: -1
  property string gmtOffsetLabel: ""
  property var daily: [] // [{date, dayName, weatherCode, tempMaxF, tempMinF}]
  property bool ready: false
  property string lastError: ""

  readonly property string unitSuffix: Settings.isLoaded && Settings.data.controlCenter.tempUnit === "celsius" ? "°C" : "°F"

  property real _lat: NaN
  property real _lon: NaN
  // Public position for NightLightService's sun-position mode.
  readonly property real latitude: _lat
  readonly property real longitude: _lon
  readonly property bool hasLocation: !isNaN(_lat) && !isNaN(_lon)

  function refreshForecast() {
    if (isNaN(root._lat) || isNaN(root._lon))
      return;
    var unit = Settings.isLoaded && Settings.data.controlCenter.tempUnit === "celsius" ? "celsius" : "fahrenheit";
    forecastProc.command = ["curl", "-s", "--max-time", "8", "https://api.open-meteo.com/v1/forecast?latitude=" + root._lat + "&longitude=" + root._lon + "&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&temperature_unit=" + unit + "&timezone=auto&forecast_days=6"];
    forecastProc.running = true;
  }

  Process {
    id: geoProc
    command: ["curl", "-s", "--max-time", "8", "http://ip-api.com/json"]
    stdout: StdioCollector {
      id: geoCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      try {
        var data = JSON.parse(geoCollector.text);
        if (data.status === "success") {
          root.cityName = data.city || "";
          root._lat = data.lat;
          root._lon = data.lon;
          root.refreshForecast();
        } else {
          root.lastError = "geolocation failed";
        }
      } catch (e) {
        root.lastError = "geolocation: " + e;
      }
    }
  }

  Process {
    id: forecastProc
    stdout: StdioCollector {
      id: forecastCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      try {
        var data = JSON.parse(forecastCollector.text);
        root.currentTempF = data.current.temperature_2m;
        root.currentWeatherCode = data.current.weather_code;
        root.gmtOffsetLabel = data.timezone_abbreviation || "";

        var days = [];
        var times = data.daily.time || [];
        for (var i = 0; i < times.length; i++) {
          var d = new Date(times[i] + "T00:00:00");
          days.push({
            "date": times[i],
            "dayName": Qt.formatDateTime(d, "ddd"),
            "weatherCode": data.daily.weather_code[i],
            "tempMaxF": Math.round(data.daily.temperature_2m_max[i]),
            "tempMinF": Math.round(data.daily.temperature_2m_min[i])
          });
        }
        root.daily = days;
        root.ready = true;
        root.lastError = "";
      } catch (e) {
        root.lastError = "forecast: " + e;
      }
    }
  }

  // Geolocation is fetched once; only the forecast refreshes.
  Component.onCompleted: geoProc.running = true

  Connections {
    target: Settings.data.controlCenter
    function onTempUnitChanged() {
      root.refreshForecast();
    }
  }

  Timer {
    interval: 30 * 60 * 1000
    running: true
    repeat: true
    onTriggered: root.refreshForecast()
  }

  // WMO codes collapsed to the categories WeatherIcon draws.
  function iconCategory(code) {
    if (code === 0)
      return "sun";
    if (code === 1 || code === 2)
      return "partly";
    if (code === 3)
      return "cloud";
    if (code === 45 || code === 48)
      return "fog";
    if (code >= 51 && code <= 67)
      return "rain";
    if (code >= 71 && code <= 77)
      return "snow";
    if (code >= 80 && code <= 82)
      return "rain";
    if (code === 85 || code === 86)
      return "snow";
    if (code >= 95)
      return "storm";
    return "cloud";
  }
}
