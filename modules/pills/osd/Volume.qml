import Quickshell
import QtQuick
import qs.widgets
import qs.config.services
import qs.config

PillBase {
  id: content
  implicitWidth: track.width + 20
  implicitHeight: track.height + 20
  property real volumeLevel: Pipewire.volumeLevel

  Rectangle {
    id: track
    width: 200
    height: 16
    anchors.centerIn: parent
    radius: 6
    clip: true
    color: Colors.outline_variant

    Rectangle {
      id: fill
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      radius: parent.radius
      color: Colors.primary
      width: parent.width * content.volumeLevel
      Behavior on width {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
      }
    }
  }
}
