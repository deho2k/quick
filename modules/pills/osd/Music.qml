import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import qs.widgets
import qs.config.services
import qs.config

PillBase {
  id: root
  // ---- state -------------------------------------------------------
  readonly property var mprisPlayer: Player.player
  readonly property bool hasPlayer: mprisPlayer !== null
  readonly property bool isPlaying: hasPlayer && mprisPlayer.isPlaying
  readonly property real progress: (hasPlayer && mprisPlayer.length > 0)
    ? Math.max(0, Math.min(1, mprisPlayer.position / mprisPlayer.length))
    : 0
  readonly property real volumeLevel: hasPlayer ? Math.max(0, Math.min(1, mprisPlayer.volume)) : 0

  implicitWidth: container.width + 20
  implicitHeight: container.height + 10

  // keep position ticking while playing so the progress bar actually moves
  // (Quickshell doesn't poll position on its own — see MprisPlayer docs)
  Timer {
    running: root.hasPlayer && root.isPlaying
    interval: 1000
    repeat: true
    onTriggered: root.mprisPlayer.positionChanged()
  }

  Rectangle {
    id: container
    width: 320
    height: mainColumn.implicitHeight + 28
    anchors.centerIn: parent
    radius: 18
    color: "transparent"

    Column {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: 14
      spacing: 10

      // ---- now playing row -----------------------------------------
      Row {
        width: parent.width
        spacing: 10

        Rectangle {
          id: artFrame
          width: 42
          height: 42
          radius: 10
          clip: true
          color: Colors.surface_variant
          anchors.verticalCenter: parent.verticalCenter

          Image {
            id: art
            anchors.fill: parent
            source: root.hasPlayer ? (root.mprisPlayer.trackArtUrl || "") : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
          }

          StyledText {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: "♪"
            font.pixelSize: 16
            color: Colors.on_surface_variant
          }
        }

        Column {
          id: textCol
          width: parent.width - artFrame.width - controls.width - parent.spacing * 2
          spacing: 3
          anchors.verticalCenter: parent.verticalCenter

          StyledText {
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: 13
            font.bold: true
            color: Colors.on_surface
            text: root.hasPlayer ? (root.mprisPlayer.trackTitle || "Unknown Title") : "Nothing playing"
          }

          StyledText {
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: 11
            color: Colors.on_surface_variant
            text: root.hasPlayer ? (root.mprisPlayer.trackArtist || "Unknown Artist") : ""
          }
        }

        Row {
          id: controls
          spacing: 8
          anchors.verticalCenter: parent.verticalCenter
          Item {
            width: 26
            height: 26
            StyledText {
              anchors.centerIn: parent
              text: root.isPlaying ? "⏸" : "▶"
              font.pixelSize: 15
              color: Colors.on_surface
            }
          }
        }
      }

      // ---- progress bar --------------------------------------------
      Rectangle {
        width: parent.width
        height: 3
        radius: 1.5
        color: Colors.outline_variant

        Rectangle {
          height: parent.height
          radius: parent.radius
          color: Colors.primary
          width: parent.width * root.progress
          Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        }
      }

      // ---- volume bar -------------------------------------------------
      Row {
        width: parent.width
        spacing: 8

        StyledText {
          anchors.verticalCenter: parent.verticalCenter
          text: root.volumeLevel <= 0 ? "󰝟" : (root.volumeLevel < 0.5 ? "󰖀" : "󰕾")
          font.pixelSize: 11
          color: Colors.on_surface_variant
        }

        Rectangle {
          id: volumeTrack
          width: parent.width - 24
          height: 3
          radius: 1.5
          color: Colors.outline_variant
          anchors.verticalCenter: parent.verticalCenter
          Rectangle {
            height: parent.height
            radius: parent.radius
            color: Colors.secondary
            width: parent.width * root.volumeLevel
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
          }
        }
      }
    }
  }
}
