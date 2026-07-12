import Quickshell
import QtQuick
import qs.widgets
import qs.config
import Quickshell.Hyprland

Rectangle {
  id: content
  implicitWidth: timeColumn.implicitWidth + 20
  implicitHeight: timeColumn.implicitHeight + 20
  radius: 8
  color: Colors.background
  anchors.centerIn: parent 
  property var workspaces: Hyprland.workspaces.values.filter((w) => w.id > 0)
  Row {
    id: timeColumn
    anchors.centerIn: parent 
    spacing: 20
    StyledText {
      text: Qt.formatDateTime(clock.date, "hh:mm")
    }
    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 5
      Repeater {
        model: content.workspaces
        Rectangle {
          required property HyprlandWorkspace modelData
          color: modelData.id == Hyprland.focusedWorkspace.id? Colors.error : Colors.primary
          radius: 5
          width: 15
          height: 15
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
