import QtQuick
import qs.config

Rectangle {
  radius: 16
  color: Colors.alpha(Colors.background, Settings.backgroundOpacity)
  anchors.centerIn: parent 
  property bool needsFocus: false
  signal grapFocus()
  signal removeFocus()
  signal returnToMainPill()
}
