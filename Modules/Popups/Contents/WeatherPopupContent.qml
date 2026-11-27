import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.ControlCenter
import qs.Modules.Popups

// Weather now, the next 24 hours over a temperature curve, and the week's ranges on one shared scale.
ColumnLayout {
  id: root

  // Bound to the owning SlideCard's `shown`; opening refetches a stale forecast.
  property bool active: false
  onActiveChanged: if (active)
    Weather.refresh()

  spacing: Tokens.spaceLg

  readonly property var today: Weather.daily.length > 0 ? Weather.daily[0] : null
  // One point every two hours.
  readonly property var hours: Weather.hourly.filter((h, i) => i % 2 === 0)
  readonly property real weekMin: Weather.daily.length > 0 ? Math.min(...Weather.daily.map(d => d.tempMinF)) : 0
  readonly property real weekMax: Weather.daily.length > 0 ? Math.max(...Weather.daily.map(d => d.tempMaxF)) : 1
  readonly property bool twelveHour: Settings.isLoaded && /[aA][pP]|h(?!h)/.test(Settings.data.ui.clockFormat.replace(/hh/g, ""))

  // "14:00" -> "14" or "2P", following the bar clock's format.
  function hourLabel(t) {
    const h = parseInt(t.slice(0, 2));
    if (!root.twelveHour)
      return t.slice(0, 2);
    return ((h + 11) % 12 + 1) + (h < 12 ? "A" : "P");
  }

  function timeLabel(t) {
    if (!root.twelveHour || t === "")
      return t;
    const h = parseInt(t.slice(0, 2));
    return ((h + 11) % 12 + 1) + t.slice(2) + (h < 12 ? " AM" : " PM");
  }

  function uvColor(uv) {
    if (uv >= 8)
      return Colors.error;
    if (uv >= 6)
      return Colors.tertiary;
    return Colors.surfaceText;
  }

  PopupHeader {
    title: "WEATHER"
    meta: Weather.lastUpdated > 0 ? "Updated " + root.timeLabel(Qt.formatDateTime(new Date(Weather.lastUpdated), "HH:mm")) : ""
    action: Weather.loading ? "…" : "REFRESH"
    actionColor: Colors.primary
    onActionTapped: Weather.refreshForecast()
  }

  // ---- Empty / error ----
  CcCard {
    visible: !Weather.ready

    NText {
      Layout.fillWidth: true
      Layout.topMargin: Tokens.spaceXl
      Layout.bottomMargin: Tokens.spaceXl
      horizontalAlignment: Text.AlignHCenter
      text: Weather.lastError !== "" ? "Weather unavailable: " + Weather.lastError : "Loading the forecast…"
      color: Colors.labelText
      size: NText.Size.BodySm
      wrapMode: Text.WordWrap
    }
  }

  // ---- Now ----
  CcCard {
    visible: Weather.ready

    RowLayout {
      Layout.fillWidth: true
      spacing: Tokens.spaceXl

      WeatherIcon {
        Layout.preferredWidth: 64
        Layout.preferredHeight: 64
        Layout.alignment: Qt.AlignVCenter
        glyphScale: 2.4
        night: !Weather.isDay
        category: Weather.iconCategory(Weather.currentWeatherCode)
      }

      ColumnLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: Tokens.spaceXs

        NText {
          text: Weather.cityName.toUpperCase()
          tracking: true
          color: Colors.labelText
          size: NText.Size.LabelXs
        }
        NText {
          text: isNaN(Weather.currentTempF) ? "--°" : Math.round(Weather.currentTempF) + "°"
          size: NText.Size.Title
        }
        NText {
          text: Weather.description(Weather.currentWeatherCode)
          size: NText.Size.BodySm
          font.weight: Font.DemiBold
        }
        NText {
          text: "Feels " + Math.round(Weather.feelsLike) + "°" + (root.today ? "  ·  H " + root.today.tempMaxF + "°  L " + root.today.tempMinF + "°" : "")
          color: Colors.surfaceTextMuted
          size: NText.Size.Caption
        }
      }

      GridLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        columns: 2
        rowSpacing: Tokens.spaceSm
        columnSpacing: Tokens.spaceSm
        uniformCellWidths: true

        Repeater {
          model: [
            {
              "label": "Humidity",
              "value": Weather.humidity + "%",
              "tint": Colors.surfaceText
            },
            {
              "label": "Wind",
              "value": Weather.windSpeed + " " + Weather.windUnit,
              "tint": Colors.surfaceText
            },
            {
              "label": "Rain",
              "value": (root.today ? root.today.rain : 0) + "%",
              "tint": root.today && root.today.rain >= 50 ? Colors.primary : Colors.surfaceText
            },
            {
              "label": "UV",
              "value": Weather.uvIndex + " " + Weather.uvLabel(Weather.uvIndex),
              "tint": root.uvColor(Weather.uvIndex)
            },
            {
              "label": "Sunrise",
              "value": root.timeLabel(Weather.sunrise),
              "tint": Colors.surfaceText
            },
            {
              "label": "Sunset",
              "value": root.timeLabel(Weather.sunset),
              "tint": Colors.surfaceText
            }
          ]

          delegate: Item {
            id: tile
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: tileCol.implicitHeight + Tokens.spaceMd * 2

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Colors.surfaceContainerHigh
            }

            ColumnLayout {
              id: tileCol
              anchors.fill: parent
              anchors.margins: Tokens.spaceMd
              anchors.leftMargin: Tokens.spaceLg
              spacing: 0

              NText {
                text: tile.modelData.label.toUpperCase()
                tracking: true
                color: Colors.labelText
                size: NText.Size.LabelXs
              }
              NText {
                Layout.fillWidth: true
                text: tile.modelData.value
                color: tile.modelData.tint
                size: NText.Size.BodySm
                font.weight: Font.DemiBold
              }
            }
          }
        }
      }
    }
  }

  // ---- Next 24 hours ----
  CcCard {
    visible: Weather.ready && root.hours.length > 1

    NText {
      text: "NEXT 24 HOURS"
      tracking: true
      color: Colors.labelText
      size: NText.Size.LabelXs
      font.weight: Font.DemiBold
    }

    Item {
      id: hoursArea

      readonly property real columnWidth: width / Math.max(1, root.hours.length)
      readonly property real labelHeight: Tokens.labelXsSize + Tokens.spaceSm
      readonly property real iconSize: 24
      // Room for a temperature label above the highest point.
      readonly property real curveTop: labelHeight + iconSize + Tokens.spaceSm + Tokens.captionSize + Tokens.spaceMd
      readonly property real curveHeight: 44
      readonly property real rainTop: curveTop + curveHeight + Tokens.spaceLg
      readonly property real rainHeight: 18
      // Rain chances at or above this are labelled.
      readonly property int rainShown: 20
      readonly property real minTemp: Math.min(...root.hours.map(h => h.temp))
      readonly property real maxTemp: Math.max(...root.hours.map(h => h.temp))

      function pointY(temp) {
        const span = Math.max(1, maxTemp - minTemp);
        return curveTop + curveHeight * (1 - (temp - minTemp) / span);
      }

      Layout.fillWidth: true
      implicitHeight: rainTop + rainHeight + labelHeight

      Canvas {
        id: curve
        anchors.fill: parent

        // Canvas colours aren't bindings, so repaint on a theme change.
        readonly property color lineColor: Colors.primary
        readonly property var points: root.hours

        onWidthChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onPointsChanged: requestPaint()

        onPaint: {
          const ctx = getContext("2d");
          ctx.reset();
          const pts = root.hours.map((h, i) => [hoursArea.columnWidth * (i + 0.5), hoursArea.pointY(h.temp)]);
          if (pts.length < 2)
            return;

          const path = () => {
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (let i = 1; i < pts.length; i++) {
              const mx = (pts[i - 1][0] + pts[i][0]) / 2;
              ctx.bezierCurveTo(mx, pts[i - 1][1], mx, pts[i][1], pts[i][0], pts[i][1]);
            }
          };
          const bottom = hoursArea.curveTop + hoursArea.curveHeight;

          ctx.beginPath();
          path();
          ctx.lineTo(pts[pts.length - 1][0], bottom);
          ctx.lineTo(pts[0][0], bottom);
          ctx.closePath();
          const grad = ctx.createLinearGradient(0, hoursArea.curveTop, 0, bottom);
          grad.addColorStop(0, Colors.alpha(lineColor, 0.35));
          grad.addColorStop(1, Colors.alpha(lineColor, 0));
          ctx.fillStyle = grad;
          ctx.fill();

          ctx.beginPath();
          path();
          ctx.strokeStyle = lineColor;
          ctx.lineWidth = 1.6;
          ctx.stroke();

          // Square markers: crux has no round shapes.
          ctx.fillStyle = lineColor;
          for (const p of pts)
            ctx.fillRect(p[0] - 2, p[1] - 2, 4, 4);
        }
      }

      Repeater {
        model: root.hours

        Item {
          id: hour

          required property var modelData
          required property int index

          x: hoursArea.columnWidth * index
          width: hoursArea.columnWidth
          height: hoursArea.height

          NText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: hour.index === 0 ? "NOW" : root.hourLabel(hour.modelData.time)
            tracking: true
            color: hour.index === 0 ? Colors.surfaceText : Colors.labelText
            size: NText.Size.LabelXs
            font.weight: hour.index === 0 ? Font.DemiBold : Font.Normal
          }

          WeatherIcon {
            y: hoursArea.labelHeight
            anchors.horizontalCenter: parent.horizontalCenter
            width: hoursArea.iconSize
            height: hoursArea.iconSize
            glyphScale: 0.85
            night: !hour.modelData.isDay
            category: Weather.iconCategory(hour.modelData.code)
          }

          NText {
            y: hoursArea.pointY(hour.modelData.temp) - height - Tokens.spaceSm
            anchors.horizontalCenter: parent.horizontalCenter
            text: hour.modelData.temp + "°"
            size: NText.Size.Caption
            font.weight: Font.DemiBold
          }

          // Rain chance as a bar on a faint track.
          Rectangle {
            y: hoursArea.rainTop
            anchors.horizontalCenter: parent.horizontalCenter
            width: 4
            height: hoursArea.rainHeight
            color: Colors.alpha(Colors.surfaceContainerHigh, 0.8)

            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width
              height: hour.modelData.rain > 0 ? Math.max(2, parent.height * hour.modelData.rain / 100) : 0
              color: Colors.alpha(Colors.primary, hour.modelData.rain >= hoursArea.rainShown ? 1 : 0.45)
            }
          }

          NText {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            visible: hour.modelData.rain >= hoursArea.rainShown
            text: hour.modelData.rain + "%"
            color: Colors.primary
            size: NText.Size.LabelXs
          }
        }
      }
    }
  }

  // ---- Week ----
  CcCard {
    visible: Weather.ready && Weather.daily.length > 0
    spacing: Tokens.spaceSm

    NText {
      Layout.bottomMargin: Tokens.spaceXs
      text: Weather.daily.length + " DAYS"
      tracking: true
      color: Colors.labelText
      size: NText.Size.LabelXs
      font.weight: Font.DemiBold
    }

    Repeater {
      model: Weather.daily

      RowLayout {
        id: day

        required property var modelData
        required property int index

        Layout.fillWidth: true
        spacing: Tokens.spaceMd

        NText {
          Layout.preferredWidth: 46
          Layout.minimumWidth: 46
          Layout.maximumWidth: 46
          text: day.index === 0 ? "TODAY" : day.modelData.dayName.toUpperCase()
          tracking: true
          color: day.index === 0 ? Colors.surfaceText : Colors.surfaceTextMuted
          size: NText.Size.Label
          font.weight: day.index === 0 ? Font.DemiBold : Font.Medium
        }

        WeatherIcon {
          Layout.preferredWidth: 24
          Layout.preferredHeight: 24
          glyphScale: 0.85
          category: Weather.iconCategory(day.modelData.weatherCode)
        }

        NText {
          Layout.preferredWidth: 34
          Layout.minimumWidth: 34
          Layout.maximumWidth: 34
          text: day.modelData.rain + "%"
          color: day.modelData.rain >= 20 ? Colors.primary : Colors.labelText
          size: NText.Size.Caption
        }

        NText {
          Layout.preferredWidth: 30
          Layout.minimumWidth: 30
          Layout.maximumWidth: 30
          horizontalAlignment: Text.AlignRight
          text: day.modelData.tempMinF + "°"
          color: Colors.surfaceTextMuted
          size: NText.Size.Caption
        }

        // The day's range against the whole week's.
        Item {
          id: range
          Layout.fillWidth: true
          implicitHeight: 6

          readonly property real span: Math.max(1, root.weekMax - root.weekMin)

          Rectangle {
            anchors.fill: parent
            color: Colors.surfaceContainerHigh
          }

          Rectangle {
            x: parent.width * (day.modelData.tempMinF - root.weekMin) / range.span
            width: Math.max(parent.height, parent.width * (day.modelData.tempMaxF - day.modelData.tempMinF) / range.span)
            height: parent.height
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0
                color: Colors.primary
              }
              GradientStop {
                position: 1
                color: Colors.tertiary
              }
            }
          }

          // The current temperature on today's bar.
          Rectangle {
            visible: day.index === 0 && !isNaN(Weather.currentTempF)
            readonly property real ratio: (Weather.currentTempF - root.weekMin) / range.span
            x: parent.width * Math.max(0, Math.min(1, ratio)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            rotation: 45
            color: Colors.surfaceText
            border.width: Tokens.borderMarker
            border.color: Colors.surface
          }
        }

        NText {
          Layout.preferredWidth: 30
          Layout.minimumWidth: 30
          Layout.maximumWidth: 30
          text: day.modelData.tempMaxF + "°"
          size: NText.Size.Caption
          font.weight: Font.DemiBold
        }

        NText {
          Layout.preferredWidth: 34
          Layout.minimumWidth: 34
          Layout.maximumWidth: 34
          horizontalAlignment: Text.AlignRight
          text: "UV " + day.modelData.uv
          color: root.uvColor(day.modelData.uv)
          size: NText.Size.Caption
        }
      }
    }
  }
}
