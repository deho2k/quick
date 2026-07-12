pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs.widgets

PillBase {
  id: content
  property string wallpapersPath: "/Pictures/walls/Wallpapers"
  implicitWidth: container.implicitWidth + 20
  implicitHeight: container.implicitHeight + 20
  FolderListModel {
    id: wallpaperModel
    folder: "file://" + Quickshell.env("HOME") + content.wallpapersPath;
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
  }
  Process {
    id: gotoCurrentWallpaper
    command: ["sh", "-c", "cat /tmp/image.txt"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || !data.trim()) return
        list.goTo("file:/" + data)
      }
    }
  }
  Column {
    id: container
    anchors.centerIn: parent 
    spacing: 4

    Rectangle {
      height: 400
      width: 1600
      color: "transparent"
      ListView {
        id: list
        orientation: ListView.Horizontal
        model: wallpaperModel
        anchors.fill: parent
        spacing: 2
        highlightMoveDuration: 500
        delegate: Rectangle {
          id: wallpaperDelegate
          required property string filePath
          readonly property bool isCurrent: ListView.isCurrentItem
          width: 350
          height: 350
          color: "transparent"
          anchors.verticalCenter: parent.verticalCenter
          Image {
            opacity: wallpaperDelegate.isCurrent ? 1 : 0.2
            scale: wallpaperDelegate.isCurrent ? 1.1 : 1
            z: wallpaperDelegate.isCurrent ? 10 : 1
            source: wallpaperDelegate.filePath
            asynchronous: true
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
          }
        }
        Keys.onPressed: (event) => {
          if(visible){
            Qt.callLater(() => list.positionViewAtIndex(list.currentIndex, ListView.Center))
            if (event.key === Qt.Key_Right || event.key === Qt.Key_K) {
              list.incrementCurrentIndex()
              event.accepted = true;
            } 
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_J) {
              list.decrementCurrentIndex()
              event.accepted = true;
            }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_A) {
              var temp = `awww img "${list.currentItem.filePath}" && matugen image "${list.currentItem.filePath}" --source-color-index 0 && qs ipc call colors reload`;
              Quickshell.execDetached(["bash", "-c", temp])
              console.log(temp)
            }
          }
        }
        function goTo(path) {
          const idx = model.indexOf(path)
          if (idx !== -1) currentIndex = idx; Qt.callLater(() => list.positionViewAtIndex(list.currentIndex, ListView.Center))
        }
        Component.onCompleted: {
          list.forceActiveFocus()
          gotoCurrentWallpaper.running = true;
          Qt.callLater(() => list.positionViewAtIndex(list.currentIndex, ListView.Center))
        }
      }
    }
  }
}
