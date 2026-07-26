pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.config.services
import qs.widgets

PanelWindow {
  id: root

  WlrLayershell.layer: WlrLayer.Background
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  anchors { top: true; bottom: true; left: true; right: true }

  mask: Region {}

  readonly property var mprisPlayer: Player.player
  readonly property bool hasPlayer: mprisPlayer !== null
  readonly property bool isPlaying: hasPlayer && mprisPlayer.isPlaying
  readonly property real progress: (hasPlayer && mprisPlayer.length > 0)
    ? Math.max(0, Math.min(1, mprisPlayer.position / mprisPlayer.length))
    : 0

  function formatTime(seconds) {
    if (!seconds || seconds < 0) seconds = 0
    const m = Math.floor(seconds / 60)
    const s = Math.floor(seconds % 60)
    return m + ":" + (s < 10 ? "0" + s : s)
  }

  // keep the position bar moving while something is playing
  Timer {
    running: root.hasPlayer && root.isPlaying
    interval: 1000
    repeat: true
    onTriggered: root.mprisPlayer.positionChanged()
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  // soft scrim so text stays legible over any wallpaper
  Rectangle {
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    height: 380
    gradient: Gradient {
      GradientStop { position: 0.0; color: Colors.alpha(Colors.scrim, 0) }
      GradientStop { position: 1.0; color: Colors.alpha(Colors.scrim, 0.55) }
    }
  }

  Column {
    id: content
    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; margins: 56 }
    spacing: 14

    StyledText {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDateTime(clock.date, "hh:mm")
      color: Colors.primary
      font.pixelSize: Config.general.fontSize * 4.8
      font.weight: Font.Light
    }

    StyledText {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
      color: Colors.on_surface_variant
      font.pixelSize: Config.general.fontSize * 1.1
      font.bold: false
    }

    // ---- now playing card ---------------------------------------------
    Rectangle {
      id: nowPlayingCard
      visible: root.hasPlayer
      radius: Config.general.radius
  color: Colors.alpha(Colors.background, Config.general.backgroundOpacity / 100)
      width: cardRow.implicitWidth + 32
      height: cardRow.implicitHeight + 24

      Row {
        id: cardRow
        anchors.centerIn: parent
        spacing: 14

        Rectangle {
          id: artFrame
          width: 48
          height: 48
          radius: Config.general.radius
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
            font.pixelSize: 18
            color: Colors.on_surface_variant
          }
        }

        Column {
          id: trackInfo
          spacing: 6
          anchors.verticalCenter: parent.verticalCenter

          Row {
            spacing: 8
            StyledText {
              text: root.isPlaying ? "⏸" : "▶"
              color: Colors.secondary
              font.pixelSize: Config.general.fontSize * 0.7
              anchors.verticalCenter: parent.verticalCenter
              textAnimateX: true
            }
            StyledText {
              text: root.hasPlayer ? (root.mprisPlayer.trackTitle || "Unknown title") : ""
              font.pixelSize: Config.general.fontSize * 0.85
              elide: Text.ElideRight
              width: Math.min(implicitWidth, 340)
              anchors.verticalCenter: parent.verticalCenter
              textAnimateX: true
            }
          }

          StyledText {
            text: root.hasPlayer ? (root.mprisPlayer.trackArtist || "Unknown artist") : ""
            color: Colors.on_surface_variant
            font.bold: false
            font.pixelSize: Config.general.fontSize * 0.65
            textAnimateX: true
          }

          Row {
            spacing: 8

            StyledText {
              text: root.hasPlayer ? root.formatTime(root.mprisPlayer.position) : "0:00"
              color: Colors.on_surface_variant
              font.bold: false
              font.pixelSize: Config.general.fontSize * 0.55
              anchors.verticalCenter: parent.verticalCenter
              textAnimation: false
            }

            Rectangle {
              width: 260
              height: 4
              radius: 2
              color: Colors.outline_variant
              anchors.verticalCenter: parent.verticalCenter

              Rectangle {
                height: parent.height
                radius: parent.radius
                color: Colors.primary
                width: parent.width * root.progress
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
              }
            }

            StyledText {
              text: root.hasPlayer ? root.formatTime(root.mprisPlayer.length) : "0:00"
              color: Colors.on_surface_variant
              font.bold: false
              font.pixelSize: Config.general.fontSize * 0.55
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }
    }
  }
}
