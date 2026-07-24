import Quickshell
import QtQuick
import qs.widgets
import qs.config.services
import qs.config
import Quickshell.Hyprland

PillBase {
  id: content
  implicitWidth: 50
  implicitHeight: column.implicitHeight + 24
  property var workspaces: Hyprland.workspaces.values.filter((w) => w.id > 0)

  Column {
    id: column
    anchors.centerIn: parent
    width: parent.width - 12
    spacing: 18

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 2
      StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "hh")
        font.pixelSize: Config.general.fontSize
      }
      StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "mm")
        font.pixelSize: Config.general.fontSize
      }
      Rectangle {
        width: 30
        height: 40
        color: Colors.secondary_container
        radius: 6

        Column {
          anchors.centerIn: parent
          StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "d")
            font.pixelSize: Config.general.fontSize * 0.6
            color: Colors.secondary
          }
          StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "MM")
            font.pixelSize: Config.general.fontSize * 0.6
            color: Colors.secondary
          }
        }
      }
    }

    Rectangle { width: parent.width; height: 1; color: Colors.outline_variant; opacity: 0.4 }

    // -- workspaces ------------------------------------------------------
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 6
      Repeater {
        model: content.workspaces
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.OutExpo } }
          Behavior on color { ColorAnimation { duration: 260 } }
          color: modelData.id == Hyprland.focusedWorkspace.id ? Colors.primary : Colors.primary_container
          radius: 6
          width: Config.general.fontSize * 0.8
          height: modelData.id == Hyprland.focusedWorkspace.id ? Config.general.fontSize * 1 : Config.general.fontSize * 0.8
        }
      }
    }

    Column {
      visible: Player.player != null
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 8

      Rectangle { width: column.width; height: 1; color: Colors.outline_variant; opacity: 0.4 }

      StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: ""
        font.pixelSize: Config.general.fontSize * 0.8
      }
      StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Player.player && Player.player.isPlaying ? "⏸" : "▶"
        font.pixelSize: Config.general.fontSize * 0.6
      }
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
