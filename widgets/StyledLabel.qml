import QtQuick
import qs.config

Row {
  id: root
  property string icon: ""
  property string text: "text"
  property int maxWidth: 220
  StyledText {
    anchors.verticalCenter: parent.verticalCenter
    text: root.icon + " "
  }
  StyledText {
    color: Colors.secondary
    width: Math.min(implicitWidth, root.maxWidth)
    anchors.verticalCenter: parent.verticalCenter
    text: root.text
  }
}
