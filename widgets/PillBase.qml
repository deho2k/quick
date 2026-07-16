import QtQuick
import qs.config

Rectangle {
  radius: Config.general.radius
  color: Colors.alpha(Colors.background, Config.general.backgroundOpacity)
  anchors.centerIn: parent 
  property bool needsFocus: false
  signal grapFocus()
  signal removeFocus()
  signal returnToMainPill()
}
