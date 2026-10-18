import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Commons
import qs.Widgets
import qs.Services

// Notification stack; cards dismiss on per-urgency timeouts from settings, never for resident ones.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property var notifications: Notifs.notifications
  readonly property int visibleCap: Settings.data.notifications.maxVisible
  readonly property var visibleNotifications: notifications.slice(0, visibleCap)
  readonly property int earlierCount: Math.max(0, notifications.length - visibleCap)
  readonly property string pos: Settings.data.notifications.position
  readonly property string barPos: Settings.isLoaded && root.targetScreen ? Settings.getBarPositionForScreen(root.targetScreen.name) : "top"
  // Clears the bar only on the edge it actually occupies.
  function edgeInset(edge: string): int {
    return root.barPos === edge ? Tokens.barExtent + Tokens.barMargin + 8 : 14;
  }
  readonly property int padTop: root.pos.startsWith("top") ? root.edgeInset("top") : 14
  readonly property int padBottom: root.pos.startsWith("bottom") ? root.edgeInset("bottom") : 14
  readonly property int padLeft: root.pos.endsWith("left") ? root.edgeInset("left") : 14
  readonly property int padRight: root.pos.endsWith("right") ? root.edgeInset("right") : 14

  readonly property bool shownOnThisScreen: Settings.data.notifications.monitors.length === 0 || (root.targetScreen && Settings.data.notifications.monitors.includes(root.targetScreen.name))

  visible: Settings.data.notifications.enabled && !Settings.data.notifications.doNotDisturb && notifications.length > 0 && root.shownOnThisScreen
  color: "transparent"

  // Sized to the stack and corner-anchored, so empty space never blocks clicks and no mask is needed.
  anchors {
    top: root.pos === "top_left" || root.pos === "top_right"
    bottom: root.pos === "bottom_left" || root.pos === "bottom_right"
    left: root.pos === "top_left" || root.pos === "bottom_left"
    right: root.pos === "top_right" || root.pos === "bottom_right"
  }
  implicitWidth: 388 + root.padLeft + root.padRight
  implicitHeight: stack.implicitHeight + root.padTop + root.padBottom

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-notifications"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  ColumnLayout {
    id: stack
    // Plain x/y, not conditional anchors, which go stale (docs/qml-gotchas.md).
    x: root.padLeft
    y: root.padTop
    width: 388
    spacing: 8

    Repeater {
      model: root.visibleNotifications

      delegate: Item {
        id: card
        required property var modelData
        Layout.fillWidth: true
        Layout.preferredHeight: cardColumn.implicitHeight + 24

        // Fade and scale in; position is owned by the ColumnLayout.
        opacity: 0
        scale: 0.96
        Component.onCompleted: enterAnim.start()

        ParallelAnimation {
          id: enterAnim
          NumberAnimation {
            target: card
            property: "opacity"
            to: 1
            duration: Tokens.durationNotifEnter
            easing.type: Tokens.easingNotifEnter
          }
          NumberAnimation {
            target: card
            property: "scale"
            to: 1
            duration: Tokens.durationNotifEnter
            easing.type: Tokens.easingNotifEnter
          }
        }

        readonly property int urgencyLevel: modelData.urgency
        readonly property color urgencyColor: urgencyLevel === NotificationUrgency.Critical ? Colors.primary : (urgencyLevel === NotificationUrgency.Low ? Colors.outline : Colors.tertiary)

        Timer {
          readonly property int _urgencySec: card.urgencyLevel === NotificationUrgency.Critical ? Settings.data.notifications.criticalUrgencyDurationSec : (card.urgencyLevel === NotificationUrgency.Low ? Settings.data.notifications.lowUrgencyDurationSec : Settings.data.notifications.normalUrgencyDurationSec)
          // An app's own positive expireTimeout wins when respectAppExpireTimeout is on.
          readonly property int _effectiveMs: (Settings.data.notifications.respectAppExpireTimeout && card.modelData && card.modelData.expireTimeout > 0) ? card.modelData.expireTimeout : _urgencySec * 1000
          running: card.modelData && !card.modelData.resident && _effectiveMs > 0
          interval: _effectiveMs
          onTriggered: if (card.modelData)
            card.modelData.dismiss()
        }

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferModule
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Colors.alpha(Colors.surfaceContainer, Settings.data.notifications.backgroundOpacity)
          strokeColor: Colors.outlineVariant
          strokeWidth: Tokens.borderModule
          shadow: true
          shadowBlur: Tokens.shadowBlurCard
          shadowOpacity: Tokens.shadowOpacityCard
          shadowOffset: Tokens.shadowOffsetCard
          rimLight: true
          rimOpacity: Tokens.rimOpacityCard
        }

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: 2
          color: card.urgencyColor
        }

        ColumnLayout {
          id: cardColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 12
          anchors.leftMargin: 16
          spacing: 4

          RowLayout {
            Layout.fillWidth: true
            NText {
              tracking: true
              text: (card.modelData.appName || "").toUpperCase()
              color: Colors.labelText
              size: NText.Size.LabelXs
            }
            Item {
              Layout.fillWidth: true
            }
            NText {
              text: "NOW"
              color: Colors.labelText
              size: NText.Size.LabelXs
            }
          }

          NText {
            Layout.fillWidth: true
            text: card.modelData.summary || ""
            color: Colors.surfaceText
            size: NText.Size.BodySm
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }

          NText {
            Layout.fillWidth: true
            visible: (card.modelData.body || "") !== ""
            text: card.modelData.body || ""
            color: Colors.surfaceTextMuted
            size: NText.Size.BodySm
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 0
            visible: (card.modelData.actions || []).length > 0 || true

            // Adjoining bordered cells with collapsed shared edges; only the first cell draws its own left edge.
            Repeater {
              model: card.modelData.actions || []
              delegate: Rectangle {
                id: actionCell
                required property var modelData
                required property int index
                readonly property bool isPrimary: index === 0
                readonly property color tint: isPrimary ? Colors.primary : Colors.labelText
                Layout.preferredHeight: 26
                Layout.fillWidth: true
                color: actHover.hovered ? Colors.alpha(Colors.primary, 0.14) : "transparent"

                Rectangle {
                  visible: actionCell.isPrimary
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: Tokens.borderDivider
                  color: actionCell.tint
                }
                Rectangle {
                  anchors.top: parent.top
                  anchors.left: parent.left
                  anchors.right: parent.right
                  height: Tokens.borderDivider
                  color: actionCell.tint
                }
                Rectangle {
                  anchors.bottom: parent.bottom
                  anchors.left: parent.left
                  anchors.right: parent.right
                  height: Tokens.borderDivider
                  color: actionCell.tint
                }
                Rectangle {
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: Tokens.borderDivider
                  color: actionCell.tint
                }

                NText {
                  tracking: true
                  anchors.centerIn: parent
                  text: actionCell.modelData.text.toUpperCase()
                  color: actionCell.tint
                  size: NText.Size.LabelXs
                }
                HoverHandler {
                  id: actHover
                  cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                  onTapped: actionCell.modelData.invoke()
                }
              }
            }

            Rectangle {
              id: dismissCell
              readonly property bool isPrimary: (card.modelData.actions || []).length === 0
              readonly property color tint: isPrimary ? Colors.error : Colors.labelText
              Layout.preferredHeight: 26
              Layout.fillWidth: true
              color: dismissHover.hovered ? Colors.alpha(Colors.error, 0.14) : "transparent"

              Rectangle {
                visible: dismissCell.isPrimary
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Tokens.borderDivider
                color: dismissCell.tint
              }
              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: Tokens.borderDivider
                color: dismissCell.tint
              }
              Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: Tokens.borderDivider
                color: dismissCell.tint
              }
              Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Tokens.borderDivider
                color: dismissCell.tint
              }

              NText {
                tracking: true
                anchors.centerIn: parent
                text: "DISMISS"
                color: dismissCell.tint
                size: NText.Size.LabelXs
              }
              HoverHandler {
                id: dismissHover
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: card.modelData.dismiss()
              }
            }
          }
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 28
      visible: root.notifications.length > 0
      color: Colors.surfaceContainerLow

      RowLayout {
        anchors.fill: parent
        anchors.margins: 9

        NText {
          tracking: true
          visible: root.earlierCount > 0
          text: root.earlierCount + " EARLIER"
          color: Colors.labelText
          size: NText.Size.LabelXs
        }
        Item {
          Layout.fillWidth: true
        }
        NText {
          tracking: true
          text: "CLEAR ALL"
          color: Colors.primary
          size: NText.Size.LabelXs

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: Notifs.clearAll()
          }
        }
      }
    }
  }
}
