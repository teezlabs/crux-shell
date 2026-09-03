import QtQuick
import qs.Commons

// Hairline rule. Flat, not noctalia's gradient fade — crux's language is
// hard edges.
Rectangle {
  property bool vertical: false

  implicitWidth: vertical ? Tokens.borderDivider : 0
  implicitHeight: vertical ? 0 : Tokens.borderDivider
  color: Color.surfaceContainerHigh
}
