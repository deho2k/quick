import Quickshell
import QtQuick
import qs.widgets
import qs.config.services
import qs.config
import Quickshell.Hyprland
import Quickshell.Widgets

PillBase {
  id: content
  implicitWidth: 50
  implicitHeight: column.implicitHeight + 12
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
    }

    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      height: 120
      width: 20
      ListView {
        anchors.centerIn: parent
        width: parent.width
        height: Math.min(parent.height, contentHeight)
        spacing: 6
        interactive: false // Disables touch/drag scrolling since this is an indicator
        Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.OutExpo } }

        model: content.workspaces
        delegate: Rectangle {
          anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

          Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.OutExpo } }
          Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.OutExpo } }
          Behavior on color { ColorAnimation { duration: 260 } }

          radius: 1
          color: Hyprland.activeToplevel.workspace.id < 0 && modelData.id == Hyprland.focusedWorkspace.id 
            ? "limegreen" 
            : modelData.id == Hyprland.focusedWorkspace.id 
            ? Colors.primary 
            : Colors.primary_container

          width: Hyprland.activeToplevel.workspace.id < 0 && modelData.id == Hyprland.focusedWorkspace.id 
            ? Config.general.fontSize 
            : Config.general.fontSize * 0.7
          height: modelData.id == Hyprland.focusedWorkspace.id 
            ? Config.general.fontSize 
            : Config.general.fontSize * 0.7
        }
      }
    }


    Column {
      visible: Player.player != null
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 8


      ClippingRectangle {
        id: artFrame
        anchors.horizontalCenter: parent.horizontalCenter
        width: 42
        height: 42
        radius: content.radius
        Image {
          id: art
          anchors.fill: parent
          source: Player.player.trackArtUrl
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          visible: status === Image.Ready
        }
        StyledText {
          anchors.centerIn: parent
          text: Player.player && Player.player.isPlaying ? "⏸" : "▶"
          color: "black"
          font.pixelSize: Config.general.fontSize
        }
      }
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
