import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets
import qs.Services

// Which shader transition plays; shaders are compiled .qsb files in Assets/Shaders.
NScrollView {
  id: root
  contentHeight: col.implicitHeight


  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Switch transition"
      description: "Animated shader transition when the wallpaper changes. Check more than one to pick randomly each time."

      Flow {
        Layout.fillWidth: true
        spacing: 4

        NMultiSelect {
          model: [
            {
              "key": "fade",
              "label": "Fade"
            },
            {
              "key": "wipe",
              "label": "Wipe"
            },
            {
              "key": "disc",
              "label": "Disc"
            },
            {
              "key": "stripes",
              "label": "Stripes"
            },
            {
              "key": "pixelate",
              "label": "Pixelate"
            },
            {
              "key": "honeycomb",
              "label": "Honeycomb"
            }
          ]
          selected: Settings.data.wallpaper.transitionType
          minSelected: 1
          uppercase: false
          onChanged: selection => Settings.data.wallpaper.transitionType = selection
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
          Layout.fillWidth: true
          NText {
            tracking: true
            text: "DURATION"
            color: Colors.labelText
            size: NText.Size.LabelXs
            Layout.fillWidth: true
          }
          NText {
            text: Settings.data.wallpaper.transitionDuration + " ms"
            color: Colors.surfaceText
            size: NText.Size.BodySm
          }
        }

        NSlider {
          Layout.fillWidth: true
          from: 200
          to: 2000
          stepSize: 50
          value: Settings.data.wallpaper.transitionDuration
          onMoved: value => Settings.data.wallpaper.transitionDuration = Math.round(value)
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
          Layout.fillWidth: true
          NText {
            tracking: true
            text: "EDGE SMOOTHNESS"
            color: Colors.labelText
            size: NText.Size.LabelXs
            Layout.fillWidth: true
          }
          NText {
            text: Settings.data.wallpaper.transitionEdgeSmoothness.toFixed(2)
            color: Colors.surfaceText
            size: NText.Size.BodySm
          }
        }

        NSlider {
          Layout.fillWidth: true
          from: 0
          to: 0.3
          stepSize: 0.01
          value: Settings.data.wallpaper.transitionEdgeSmoothness
          onMoved: value => Settings.data.wallpaper.transitionEdgeSmoothness = value
        }
      }
    }
  }
}
