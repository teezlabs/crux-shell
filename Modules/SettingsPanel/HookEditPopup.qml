import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras

// Modal command-editor popup for a single hook — the crux-native equivalent
// of noctalia's HookEditPopup (which used a QtQuick.Controls Popup over
// Overlay.overlay; crux's popup language is PanelWindow overlays, so this
// is a full-screen scrim + centered chamfered card, same structure as
// PowerMenuWindow but with a text field). The caller (HooksListSubTab)
// provides the label/description/placeholder/current value plus save and
// test callbacks via openFor(); SAVE commits the edited command, TEST runs
// the hook's runner with sample placeholder values (see the subtab).
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  property string hookLabel: ""
  property string hookDescription: ""
  property string hookPlaceholder: ""
  property string initialValue: ""

  // Callbacks wired per-open by HooksListSubTab: saveCb(newValue), testCb().
  property var onSave: null
  property var onTest: null

  function openFor(label, description, placeholder, value, saveCb, testCb) {
    root.hookLabel = label;
    root.hookDescription = description;
    root.hookPlaceholder = placeholder;
    root.initialValue = value;
    root.onSave = saveCb;
    root.onTest = testCb;
    commandInput.text = value;
    root.visible = true;
    commandInput.forceActiveFocus();
  }

  visible: false
  color: Color.alpha(Color.surface, 0.75)

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-hook-edit"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  Item {
    id: card
    anchors.centerIn: parent
    width: 480
    height: editCol.implicitHeight + 30

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: editCol
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: root.hookLabel
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodyLgSize
          font.weight: Font.DemiBold
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        Text {
          text: "×"
          color: Color.surfaceTextMuted
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.visible = false
          }
        }
      }

      Text {
        text: root.hookDescription
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
        font.letterSpacing: Tokens.captionSize * Tokens.captionTracking
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 30

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Color.surface
          strokeColor: commandInput.activeFocus ? Color.primary : Color.outline
          strokeWidth: Tokens.borderModule
        }

        TextInput {
          id: commandInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: Text.AlignVCenter
          color: Color.surfaceText
          font.family: Tokens.monoFontFamily
          font.pixelSize: Tokens.bodySmSize
          selectByMouse: true
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Test runs the hook's runner with sample values — safe to fire
        // from here (it's exactly what a real event would run).
        Item {
          width: testLabel.implicitWidth + 24
          height: 28

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: testHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
            strokeColor: Color.outline
            strokeWidth: Tokens.borderModule
          }

          Text {
            id: testLabel
            anchors.centerIn: parent
            text: "TEST"
            color: root.onTest && commandInput.text !== "" ? Color.surfaceText : Color.surfaceTextMuted
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }

          HoverHandler {
            id: testHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            enabled: root.onTest && commandInput.text !== ""
            onTapped: root.onTest()
          }
        }

        Item {
          Layout.fillWidth: true
        }

        Item {
          width: cancelLabel.implicitWidth + 24
          height: 28

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Color.surfaceContainer
            strokeColor: Color.outline
            strokeWidth: Tokens.borderModule
          }

          Text {
            id: cancelLabel
            anchors.centerIn: parent
            text: "CANCEL"
            color: Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.visible = false
          }
        }

        Item {
          width: saveLabel.implicitWidth + 24
          height: 28

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: saveHover.hovered ? Color.primaryContainer : Color.primaryContainer
            strokeColor: Color.primary
            strokeWidth: Tokens.borderModule
          }

          Text {
            id: saveLabel
            anchors.centerIn: parent
            text: "SAVE"
            color: Color.primaryContainerText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }

          HoverHandler {
            id: saveHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: {
              if (root.onSave)
                root.onSave(commandInput.text);
              root.visible = false;
            }
          }
        }
      }
    }
  }
}
