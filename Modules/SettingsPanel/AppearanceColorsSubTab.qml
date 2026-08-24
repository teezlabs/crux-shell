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

  Text {
    text: "Live-updated by wallpaper-derived theming too (see Wallpaper tab) — edits here are overwritten the next time a wallpaper is applied."
    color: Color.mOnSurfaceVariant
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: Style.fontSizeXS
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Layout.bottomMargin: 4
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
