import QtQuick
import qs.config

Rectangle {
  radius: 16
  color: Colors.alpha(Colors.background, Config.general.backgroundOpacity)
  anchors.centerIn: parent 
  property bool needsFocus: false
  signal grapFocus()
  signal removeFocus()
  signal returnToMainPill()
}
