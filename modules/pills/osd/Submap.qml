pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.widgets
import qs.config.services
import qs.config

PillBase {
  id: content
  implicitWidth: container.implicitWidth + 20
  implicitHeight: container.implicitHeight + 20


  ListView {
    id: container
    model: Hypr.currentSubmapKeys
    implicitWidth: 240
    implicitHeight: contentHeight
    interactive: false
    spacing:     0
    delegate: Rectangle {
      id: bindRow

      required property string bindKey
      required property string description
      width:  container.width
      height: 52
      color:  "transparent"
      Rectangle {
        id: keyBadge
        anchors {
          left:           parent.left
          leftMargin:     16
          verticalCenter: parent.verticalCenter
        }
        height: 24
        width:  keyLabel.implicitWidth + 14
        radius: 5
        color:        Qt.rgba(1, 1, 1, 0.06)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1

        StyledText {
          id: keyLabel
          anchors.centerIn: parent
          text:            bindRow.bindKey
          font.pixelSize:  11
          font.weight:     Font.Medium
          opacity:         0.85
        }
      }
      StyledText {
        anchors {
          left:           keyBadge.right
          leftMargin:     12
          right:          parent.right
          rightMargin:    16
          verticalCenter: parent.verticalCenter
        }
        text:           bindRow.description
        font.pixelSize: 13
        font.weight:    Font.Normal
        opacity:        0.85
        elide:          Text.ElideRight
      }
      Rectangle {
        anchors {
          bottom:      parent.bottom
          left:        parent.left
          right:       parent.right
          leftMargin:  16
          rightMargin: 16
        }
        height:  1
        color:   Colors.on_surface
        opacity: 0.06
      }
    }
  }
}
