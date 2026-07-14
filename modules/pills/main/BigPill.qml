import Quickshell
import QtQuick
import qs.widgets
import qs.config
import Quickshell.Hyprland

PillBase {
  id: content
  implicitWidth: timeColumn.implicitWidth + 20
  implicitHeight: timeColumn.implicitHeight + 20
  property var workspaces: Hyprland.workspaces.values.filter((w) => w.id > 0)
  Row {
    id: timeColumn
    anchors.centerIn: parent 
    spacing: 20
    StyledText { text: Qt.formatDateTime(clock.date, "hh:mm") }
    Row {
      spacing: 5
      anchors.verticalCenter: parent.verticalCenter
      Repeater {
        model: content.workspaces
        Rectangle {
          required property HyprlandWorkspace modelData
          color: modelData.id == Hyprland.focusedWorkspace.id? Colors.primary : Colors.primary_container
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
