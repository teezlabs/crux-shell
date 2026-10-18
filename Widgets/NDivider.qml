import QtQuick
import qs.Commons

// Hairline rule; flat, no gradient fade.
Rectangle {
  property bool vertical: false

  implicitWidth: vertical ? Tokens.borderDivider : 0
  implicitHeight: vertical ? 0 : Tokens.borderDivider
  color: Colors.surfaceContainerHigh
}
