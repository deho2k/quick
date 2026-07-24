import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
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

  implicitWidth: 50
  implicitHeight: mainColumn.implicitHeight + 24

  // keep position ticking while playing so the progress bar actually moves
  // (Quickshell doesn't poll position on its own — see MprisPlayer docs)
  Timer {
    running: root.hasPlayer && root.isPlaying
    interval: 1000
    repeat: true
    onTriggered: root.mprisPlayer.positionChanged()
  }

  Column {
    id: mainColumn
    anchors.centerIn: parent
    width: parent.width
    spacing: 14

    // ---- album art / play state ---------------------------------------
    ClippingRectangle {
      id: artFrame
      anchors.horizontalCenter: parent.horizontalCenter
      width: 40
      height: 40
      radius: 10
      clip: true
      color: Colors.surface_variant

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

    StyledText {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.isPlaying ? "⏸" : "▶"
      font.pixelSize: 15
      color: Colors.on_surface
    }

    // ---- title / artist, rotated to read along the sidebar ------------
    Item {
      id: trackInfo
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width
      height: 130 // budget for how much text can read before eliding

      Column {
        id: trackTextColumn
        anchors.centerIn: parent
        rotation: -90
        width: trackInfo.height // pre-rotation width becomes the reading length
        spacing: 2

        StyledText {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
          font.pixelSize: 16
          font.bold: true
          color: Colors.on_surface
          text: root.hasPlayer ? (root.mprisPlayer.trackTitle || "Unknown Title") : "Nothing playing"
        }

        StyledText {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
          font.pixelSize: 14
          color: Colors.on_surface_variant
          text: root.hasPlayer ? (root.mprisPlayer.trackArtist || "Unknown Artist") : ""
        }
      }
    }

    Rectangle { width: parent.width; height: 1; color: Colors.outline_variant; opacity: 0.4 }

    // ---- progress (vertical fill) --------------------------------------
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 3
      height: 150
      radius: 1.5
      color: Colors.outline_variant

      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        radius: parent.radius
        color: Colors.primary
        height: parent.height * root.progress
        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
      }
    }

    // ---- volume (vertical fill) -----------------------------------------
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 6

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 3
        height: 80
        radius: 1.5
        color: Colors.outline_variant

        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          radius: parent.radius
          color: Colors.secondary
          height: parent.height * root.volumeLevel
          Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }
      }

      StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.volumeLevel <= 0 ? "󰝟" : (root.volumeLevel < 0.5 ? "󰖀" : "󰕾")
        font.pixelSize: 11
        color: Colors.on_surface_variant
      }
    }
  }
}
