import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  spacing: 14

  readonly property var colorFields: [
    {
      "label": "Primary",
      "key": "mPrimary"
    },
    {
      "label": "On primary",
      "key": "mOnPrimary"
    },
    {
      "label": "Secondary",
      "key": "mSecondary"
    },
    {
      "label": "On secondary",
      "key": "mOnSecondary"
    },
    {
      "label": "Surface",
      "key": "mSurface"
    },
    {
      "label": "On surface",
      "key": "mOnSurface"
    },
    {
      "label": "Surface var.",
      "key": "mSurfaceVariant"
    },
    {
      "label": "On surf. var.",
      "key": "mOnSurfaceVariant"
    },
    {
      "label": "Outline",
      "key": "mOutline"
    },
    {
      "label": "Error",
      "key": "mError"
    }
  ]

  RowLayout {
    spacing: 10
    Text {
      text: "Font"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      Layout.preferredWidth: 90
    }
    TextInput {
      Layout.preferredWidth: 200
      text: Settings.data.ui.fontFamily
      color: Color.mOnSurface
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      onEditingFinished: Settings.data.ui.fontFamily = text

      Rectangle {
        z: -1
        anchors.fill: parent
        anchors.margins: -4
        color: Color.mSurfaceVariant
        radius: Style.radiusXXS
      }
    }
  }

  RowLayout {
    spacing: 10
    Text {
      text: "Corner radius"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      Layout.preferredWidth: 90
    }
    Slider {
      Layout.preferredWidth: 200
      from: 0
      to: 3
      stepSize: 0.1
      value: Settings.data.theme.radiusRatio
      onMoved: Settings.data.theme.radiusRatio = value
    }
    Text {
      text: Settings.data.theme.radiusRatio.toFixed(1) + "x"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
    }
  }

  RowLayout {
    spacing: 10
    Text {
      text: "Bar opacity"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      Layout.preferredWidth: 90
    }
    Slider {
      Layout.preferredWidth: 200
      from: 0.2
      to: 1
      stepSize: 0.05
      value: Settings.data.theme.barOpacity
      onMoved: Settings.data.theme.barOpacity = value
    }
    Text {
      text: Math.round(Settings.data.theme.barOpacity * 100) + "%"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
    }
  }

  Text {
    text: "Colors"
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeS
    Layout.topMargin: 8
  }

  GridLayout {
    columns: 2
    rowSpacing: 8
    columnSpacing: 20

    Repeater {
      model: root.colorFields

      delegate: RowLayout {
        id: fieldRow
        required property var modelData
        spacing: 10

        Rectangle {
          width: 22
          height: 22
          radius: Style.radiusXXS
          color: Settings.data.theme[fieldRow.modelData.key]
          border.color: Color.mOutline
          border.width: 1
        }

        Text {
          text: fieldRow.modelData.label
          color: Color.mOnSurfaceVariant
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
          Layout.preferredWidth: 80
        }

        TextInput {
          Layout.preferredWidth: 90
          text: Settings.data.theme[fieldRow.modelData.key]
          color: Color.mOnSurface
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
          onEditingFinished: {
            if (/^#[0-9a-fA-F]{6,8}$/.test(text))
              Settings.data.theme[fieldRow.modelData.key] = text;
          }

          Rectangle {
            z: -1
            anchors.fill: parent
            anchors.margins: -4
            color: Color.mSurfaceVariant
            radius: Style.radiusXXS
          }
        }
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
