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
  readonly property int rowHeight: 32
  property int page: 0

  function nextPage(direction) {
    content.page = (content.page + direction) % Config.settingsKeys.length
    page.text = Config.settingsKeys[content.page]
    list.currentIndex = 0
  }

  function adjustCurrentValue(direction) {
    const category = Config.settingsKeys[content.page]
    const key = list.model[list.currentIndex]
    const val = Config.adapter[category][key]
    if (typeof val === "boolean") {
      Config.adapter[category][key] = !val
    } else if (typeof val === "number") {
      if (content.step && !Number.isInteger(content.step)) {
        const next = Math.min(1, Math.max(0, val + direction * content.step))
        Config.adapter[category][key] = Math.round(next * 100) / 100
      } else {
        const step = content.step || 1; // Fallback to 1 if no step is defined
        Config.adapter[category][key] = Math.min(100, Math.max(0, val + direction * step))
      }
    }
  }

  Column {
    id: container
    anchors.centerIn: parent
    spacing: 8

    Row {
      anchors.leftMargin: 8
      anchors.horizontalCenter: parent.horizontalCenter
      StyledText {
        font.pixelSize: 18
        text: "< "
      }
      StyledText {
        id: page
        textAnimateX: true
        font.pixelSize: 18
        text: "page"
      }
      StyledText {
        font.pixelSize: 18
        text: " >"
      }
    }
    ListView {
      id: list
      width: 280
      height: contentHeight
      interactive: false
      spacing: 2
      model: Config.keysForPage(content.page)
      focus: true
      Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

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
          font.bold: false
          font.pixelSize: 16
          text: rowContainer.modelData.padEnd(content.labelChars, " ")
        }
        StyledText {
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: parent.right
          anchors.rightMargin: 8
          textAnimateX: true
          font.pixelSize: 16
          text: String(Config.adapter[Config.settingsKeys[content.page]][rowContainer.modelData])
        }
      }
    }

    StyledText {
      text: "k·j select - h·l adjust - Tab page"
      font.pixelSize: 12
      opacity: 0.5
    }
  }
  Component.onCompleted: {content.nextPage(0) }
}
