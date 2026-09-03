import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Modal command-editor popup for a single hook (PanelWindow scrim + card,
// like PowerMenuWindow). Caller (HooksListSubTab) drives it via openFor().
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

        NText {
          text: root.hookLabel
          color: Color.surfaceText
          size: NText.Size.BodyLg
          font.weight: Font.DemiBold
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        NText {
          text: "×"
          color: Color.surfaceTextMuted
          size: NText.Size.BodySm

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.visible = false
          }
        }
      }

      NText {
        tracking: true
        text: root.hookDescription
        color: Color.labelText
        size: NText.Size.Caption
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      NTextInput {
        id: commandInput
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        mono: true
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

          NText {
            tracking: true
            id: testLabel
            anchors.centerIn: parent
            text: "TEST"
            color: root.onTest && commandInput.text !== "" ? Color.surfaceText : Color.surfaceTextMuted
            size: NText.Size.LabelXs
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

          NText {
            tracking: true
            id: cancelLabel
            anchors.centerIn: parent
            text: "CANCEL"
            color: Color.surfaceText
            size: NText.Size.LabelXs
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

          NText {
            tracking: true
            id: saveLabel
            anchors.centerIn: parent
            text: "SAVE"
            color: Color.primaryContainerText
            size: NText.Size.LabelXs
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
