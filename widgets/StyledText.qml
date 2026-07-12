import QtQuick
import qs.config

Text {
  id: dynamicText
  property bool textAnimation: true
  property bool textAnimateX: false
  font.pixelSize: 22
  font.bold: true
  font.family: "JetBrainsMono Nerd Font"
  color: Colors.primary
  elide: Text.ElideRight
  transform: Translate { id: textTranslate; y: 0; x: 0}


  Behavior on text {
    enabled: dynamicText.textAnimation
    SequentialAnimation {
      ParallelAnimation {
        NumberAnimation { 
          target: dynamicText; property: "opacity"; to: 0 
          duration: 150; easing.type: Easing.InQuad 
        }
        NumberAnimation { 
          target: textTranslate; property: dynamicText.textAnimateX? "x": "y"; to: -10 
          duration: 150; easing.type: Easing.InQuad 
        }
      }
      PropertyAction { } 
      PropertyAction { target: textTranslate; property:dynamicText.textAnimateX? "x": "y"; value: 10 }
      ParallelAnimation {
        NumberAnimation { 
          target: dynamicText; property: "opacity"; to: dynamicText.opacity 
          duration: 250; easing.type: Easing.OutBack 
        }
        NumberAnimation { 
          target: textTranslate; property: dynamicText.textAnimateX? "x": "y"; to: textTranslate.y
          duration: 250; easing.type: Easing.OutBack 
        }
      }
    }
  }
}
