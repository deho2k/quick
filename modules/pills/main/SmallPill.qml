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
  Column {
    id: timeColumn
    anchors.centerIn: parent 
    StyledText { text: Qt.formatDateTime(clock.date, "hh:mm"); font.pixelSize: Config.general.fontSize * 1.2 }
    Row {
      spacing: 5
      anchors.horizontalCenter: parent.horizontalCenter
      Repeater {
        model: content.workspaces
        Rectangle {
          Behavior on width { NumberAnimation { duration: 560; easing.type: Easing.OutExpo } }
          Behavior on color { ColorAnimation { duration: 460 }  }
          required property HyprlandWorkspace modelData
          color: modelData.id == Hyprland.focusedWorkspace.id? Colors.primary : Colors.primary_container
          radius: 5
          width: modelData.id == Hyprland.focusedWorkspace.id? Config.general.fontSize * 0.5 : Config.general.fontSize * 0.3
          height: Config.general.fontSize * 0.3
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
