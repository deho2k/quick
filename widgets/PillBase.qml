import QtQuick
import qs.config

Rectangle {
  radius: 16
  color: Colors.background
  anchors.centerIn: parent 
  property bool needsFocus: false
  signal grapFocus()
  signal removeFocus()
  signal returnToMainPill()
}
