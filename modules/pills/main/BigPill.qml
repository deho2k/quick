import Quickshell
import QtQuick
import qs.widgets
import qs.config.services
import qs.config
import Quickshell.Hyprland

PillBase {
  id: content
  implicitWidth: container.implicitWidth + 20
  implicitHeight: container.implicitHeight + 20
  property var workspaces: Hyprland.workspaces.values.filter((w) => w.id > 0)
  Row {
    id: container
    anchors.centerIn: parent 
    spacing: 20
    Row {
      visible: Player.player != null
      StyledLabel {
        icon:  ""
        text: Player.player.trackArtist + " - " +Player.player.trackTitle 
      }
      StyledText {
        text: Player.player.isPlaying? " ⏸" : " ▶"
      }
    }
    Row {
      spacing: 5
      anchors.verticalCenter: parent.verticalCenter
      StyledText { text: ""; color: Colors.secondary_container}
      Repeater {
        model: content.workspaces
        Rectangle {
          Behavior on width { NumberAnimation { duration: 560; easing.type: Easing.OutExpo } }
          Behavior on color { ColorAnimation { duration: 460 }  }
          color: modelData.id == Hyprland.focusedWorkspace.id? Colors.primary : Colors.primary_container
          radius: 6
          width: modelData.id == Hyprland.focusedWorkspace.id? Config.general.fontSize * 1 : Config.general.fontSize * 0.8
          height: Config.general.fontSize * 0.8
          anchors.verticalCenter: parent.verticalCenter
        }
      }
      StyledText { text: ""; color: Colors.secondary_container }
    }
    StyledLabel { text: Qt.formatDateTime(clock.date, "hh:mm AP"); icon: "" }
    StyledText { text: "|"; color: Colors.secondary_container }
    StyledLabel { text: Qt.formatDateTime(clock.date, "MMM d "); icon: "" }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
//Row {
//  id: root
//  anchors.verticalCenter: parent.verticalCenter
//
//  StyledText {
//    anchors.verticalCenter: parent.verticalCenter
//    font.pixelSize: Config.general.fontSize
//    text: " "
//  }
//
//  Column {
//    anchors.verticalCenter: parent.verticalCenter
//    StyledText {
//      font.pixelSize: Config.general.fontSize * 0.4
//      color: Colors.secondary
//      text: Player.player.trackArtist
//    }
//    StyledText {
//      font.pixelSize: Config.general.fontSize * 0.6
//      width: Math.min(implicitWidth, 150)
//      color: Colors.secondary
//      text: Player.player.trackTitle
//    }
//  }
//}
