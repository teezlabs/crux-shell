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
  // [{date, dayName, weatherCode, tempMaxF, tempMinF, rain, uv}]; rain is the max precipitation chance in %.
  property var daily: []
  property bool ready: false
  property string lastError: ""

  // Current conditions beyond the temperature.
  property real feelsLike: NaN
  property int humidity: 0
  property int windSpeed: 0
  property bool isDay: true
  property int uvIndex: 0
  // The next 24 hours from the current one: [{time, temp, code, isDay, rain}].
  property var hourly: []
  // Today's, as "HH:mm" local to the forecast location.
  property string sunrise: ""
  property string sunset: ""
  property bool loading: false
  // Epoch ms of the last good forecast.
  property real lastUpdated: 0

  readonly property bool celsius: Settings.isLoaded && Settings.data.controlCenter.tempUnit === "celsius"
  readonly property string unitSuffix: celsius ? "°C" : "°F"
  readonly property string windUnit: celsius ? "km/h" : "mph"

  property real _lat: NaN
  property real _lon: NaN
  // Public position for NightLightService's sun-position mode.
  readonly property real latitude: _lat
  readonly property real longitude: _lon
  readonly property bool hasLocation: !isNaN(_lat) && !isNaN(_lon)

  // Refetches unless the last forecast is younger than ten minutes.
  function refresh() {
    if (!root.hasLocation) {
      if (!geoProc.running)
        geoProc.running = true;
      return;
    }
    if (Date.now() - root.lastUpdated > 10 * 60 * 1000)
      root.refreshForecast();
  }

  function refreshForecast() {
    if (!root.hasLocation || forecastProc.running)
      return;
    const units = "&temperature_unit=" + (root.celsius ? "celsius" : "fahrenheit") + "&wind_speed_unit=" + (root.celsius ? "kmh" : "mph");
    const current = "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day,uv_index";
    const hourly = "&hourly=temperature_2m,weather_code,precipitation_probability,is_day";
    const daily = "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,uv_index_max,sunrise,sunset";
    forecastProc.command = ["curl", "-s", "--max-time", "8", "https://api.open-meteo.com/v1/forecast?latitude=" + root._lat + "&longitude=" + root._lon + current + hourly + daily + units + "&timezone=auto&forecast_days=7"];
    root.loading = true;
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
        const data = JSON.parse(geoCollector.text);
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
      root.loading = false;
      try {
        root._apply(JSON.parse(forecastCollector.text));
        root.lastError = "";
      } catch (e) {
        root.lastError = "forecast: " + e;
      }
    }
  }

  function _apply(data) {
    const cur = data.current;
    root.currentTempF = cur.temperature_2m;
    root.currentWeatherCode = cur.weather_code;
    root.feelsLike = cur.apparent_temperature;
    root.humidity = Math.round(cur.relative_humidity_2m);
    root.windSpeed = Math.round(cur.wind_speed_10m);
    root.isDay = cur.is_day === 1;
    root.uvIndex = Math.round(cur.uv_index || 0);
    root.gmtOffsetLabel = data.timezone_abbreviation || "";

    // Times are local to the location ("2026-11-27T14:00"); start at the current hour.
    const h = data.hourly;
    const nowHour = cur.time.slice(0, 13);
    const first = Math.max(0, h.time.findIndex(t => t.slice(0, 13) === nowHour));
    const hours = [];
    for (let i = first; i < Math.min(first + 24, h.time.length); i++) {
      hours.push({
        "time": h.time[i].slice(11, 16),
        "temp": Math.round(h.temperature_2m[i]),
        "code": h.weather_code[i],
        "isDay": h.is_day[i] === 1,
        "rain": h.precipitation_probability[i] || 0
      });
    }
    root.hourly = hours;

    const d = data.daily;
    const days = [];
    for (let i = 0; i < d.time.length; i++) {
      days.push({
        "date": d.time[i],
        "dayName": Qt.formatDateTime(new Date(d.time[i] + "T00:00:00"), "ddd"),
        "weatherCode": d.weather_code[i],
        "tempMaxF": Math.round(d.temperature_2m_max[i]),
        "tempMinF": Math.round(d.temperature_2m_min[i]),
        "rain": d.precipitation_probability_max[i] || 0,
        "uv": Math.round(d.uv_index_max[i] || 0)
      });
    }
    root.daily = days;
    root.sunrise = d.sunrise.length > 0 ? d.sunrise[0].slice(11, 16) : "";
    root.sunset = d.sunset.length > 0 ? d.sunset[0].slice(11, 16) : "";

    root.lastUpdated = Date.now();
    root.ready = true;
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

  function description(code) {
    const names = {
      "0": "Clear sky",
      "1": "Mainly clear",
      "2": "Partly cloudy",
      "3": "Overcast",
      "45": "Fog",
      "48": "Rime fog",
      "51": "Light drizzle",
      "53": "Drizzle",
      "55": "Heavy drizzle",
      "56": "Freezing drizzle",
      "57": "Freezing drizzle",
      "61": "Light rain",
      "63": "Rain",
      "65": "Heavy rain",
      "66": "Freezing rain",
      "67": "Freezing rain",
      "71": "Light snow",
      "73": "Snow",
      "75": "Heavy snow",
      "77": "Snow grains",
      "80": "Light showers",
      "81": "Showers",
      "82": "Violent showers",
      "85": "Snow showers",
      "86": "Snow showers",
      "95": "Thunderstorm",
      "96": "Thunderstorm, hail",
      "99": "Thunderstorm, hail"
    };
    return names[String(code)] || "Unknown";
  }

  function uvLabel(uv) {
    if (uv >= 11)
      return "Extreme";
    if (uv >= 8)
      return "Very high";
    if (uv >= 6)
      return "High";
    if (uv >= 3)
      return "Moderate";
    return "Low";
  }
}
