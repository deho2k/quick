pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.config
import qs.widgets

PillBase {
  id: content
  implicitWidth: container.implicitWidth + 20
  implicitHeight: container.implicitHeight + 20

  readonly property real step: 0.05
  readonly property int labelChars: 20 // padding width, in characters (monospace font)
  readonly property int rowHeight: 28
  property int page: 0

  function nextPage(direction) {
    content.page = content.page + direction
    page.text = Config.settingsKeys[content.page % Config.settingsKeys.length]
    list.currentIndex = 0
  }

  function adjustCurrentValue(direction) {
    const key = list.model[list.currentIndex]
    const val = Config.adapter[key]

    if (typeof val === "boolean") {
      Config.adapter[key] = !val
    } else if (typeof val === "number") {
      const next = Math.min(1, Math.max(0, val + direction * content.step))
      Config.adapter[key] = Math.round(next * 100) / 100
    }
  }

  Column {
    id: container
    anchors.centerIn: parent
    spacing: 8

    StyledText {
      text: "Settings"
      font.pixelSize: 14
    }

    StyledText {
      id: page
      textAnimateX: true
      anchors.leftMargin: 8
      anchors.horizontalCenter: parent.horizontalCenter
      font.pixelSize: 12
      text: "page"
    }
    ListView {
      id: list
      width: 280
      height: contentHeight
      interactive: false
      spacing: 2
      model: Config.settingsKeys
      focus: true

      Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_J) { list.incrementCurrentIndex(); event.accepted = true }
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) { list.decrementCurrentIndex(); event.accepted = true }
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) { content.adjustCurrentValue(1); event.accepted = true }
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) { content.adjustCurrentValue(-1); event.accepted = true }
        else if (event.key === Qt.Key_Tab) { content.nextPage(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
      }

      Component.onCompleted: list.forceActiveFocus()

      delegate: Rectangle {
        id: rowContainer
        required property string modelData // setting name, e.g. "backgroundOpacity"
        required property int index
        width: list.width
        height: content.rowHeight
        radius: 4
        color: ListView.isCurrentItem ? Colors.outline_variant : "transparent"

        StyledText {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: 8
          font.pixelSize: 12
          text: rowContainer.modelData.padEnd(content.labelChars, " ")
        }
        StyledText {
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: parent.right
          anchors.rightMargin: 8
          textAnimateX: true
          font.pixelSize: 12
          text: String(Config.adapter[rowContainer.modelData])
        }
      }
    }

    StyledText {
      text: "k·j select - h·l adjust - Tab page"
      font.pixelSize: 10
      opacity: 0.5
    }
  }
  Component.onCompleted: {
    Config.hyprland.animations = true
    content.nextPage(0)
    console.log(Config.settingsKeys)
  }
}
