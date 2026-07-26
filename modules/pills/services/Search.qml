import Quickshell
import QtQuick
import Quickshell.Wayland
import qs.config
import qs.widgets

PillBase {
  id: content
  implicitWidth: container.implicitWidth + 24
  implicitHeight: container.implicitHeight + 24

  property var appModel: DesktopEntries.applications.values
  readonly property int rowHeight: 44
  readonly property int rowSpacing: 6
  readonly property int maxVisibleRows: 8
  readonly property int listWidth: 320

  Column {
    id: container
    anchors.centerIn: parent
    spacing: 10

    // ---- search field ---------------------------------------------------
    Rectangle {
      id: searchBox
      width: content.listWidth
      height: 44
      radius: Config.general.radius
      color: Colors.surface_container_high
      border.width: 1
      border.color: searchInput.activeFocus ? Colors.primary : Colors.outline_variant
      Behavior on border.color { ColorAnimation { duration: 150 } }

      StyledText {
        id: searchIcon
        text: ""
        font.pixelSize: Config.general.fontSize * 0.75
        color: Colors.on_surface_variant
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
      }

      Item {
        id: inputArea
        anchors {
          left: searchIcon.right; leftMargin: 10
          right: parent.right; rightMargin: 14
          verticalCenter: parent.verticalCenter
        }
        height: parent.height

        StyledText {
          anchors.fill: parent
          verticalAlignment: Text.AlignVCenter
          visible: searchInput.text.length === 0
          text: "Search apps…"
          color: Colors.on_surface_variant
          opacity: 0.6
          font.bold: false
          font.pixelSize: Config.general.fontSize * 0.75
        }

        TextInput {
          id: searchInput
          anchors.fill: parent
          verticalAlignment: TextInput.AlignVCenter
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: Config.general.fontSize * 0.75
          color: Colors.on_surface
          selectionColor: Colors.primary
          selectedTextColor: Colors.on_primary
          onTextChanged: content.filterApps(text)
          Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Down) { appList.incrementCurrentIndex() }
            else if (event.key === Qt.Key_Up) { appList.decrementCurrentIndex() }
          }
          Keys.onReturnPressed: {
            if (appList.currentItem) {
              appList.currentItem.modelData.execute()
              content.returnToMainPill()
            }
          }
          Component.onCompleted: forceActiveFocus()
        }
      }
    }

    // ---- results ----------------------------------------------------------
    Item {
      id: listWrapper
      width: content.listWidth
      // dynamic height: fits content up to maxVisibleRows, then caps + scrolls
      height: Math.min(
        content.appModel.length * content.rowHeight + Math.max(0, content.appModel.length - 1) * content.rowSpacing,
        content.maxVisibleRows * content.rowHeight + (content.maxVisibleRows - 1) * content.rowSpacing
      )

      ListView {
        id: appList
        anchors.fill: parent
        model: content.appModel
        spacing: content.rowSpacing
        clip: true
        delegate: Rectangle {
          id: row
          required property var modelData
          width: appList.width
          height: content.rowHeight
          radius: Config.general.radius
          color: row.ListView.isCurrentItem ? Colors.primary_container : "transparent"
          Behavior on color { ColorAnimation { duration: 120 } }

          Rectangle {
            id: appIconFrame
            width: 30
            height: 30
            color: "transparent"
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }

            Image {
              id: appIcon
              anchors.fill: parent
              source: row.modelData.icon ? "image://icon/" + row.modelData.icon : ""
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              visible: status === Image.Ready
            }
            StyledText {
              anchors.centerIn: parent
              visible: appIcon.status !== Image.Ready
              text: ""
              font.pixelSize: 15
              color: Colors.on_surface_variant
            }
          }

          StyledText {
            text: row.modelData.name
            font.pixelSize: Config.general.fontSize * 0.75
            font.bold: false
            color: row.ListView.isCurrentItem ? Colors.on_primary_container : Colors.on_surface
            elide: Text.ElideRight
            anchors {
              left: appIconFrame.right; leftMargin: 10
              right: parent.right; rightMargin: 12
              verticalCenter: parent.verticalCenter
            }
          }
        }
      }

      StyledText {
        visible: content.appModel.length === 0
        anchors.centerIn: parent
        text: "No matching apps"
        color: Colors.on_surface_variant
        font.bold: false
        font.pixelSize: Config.general.fontSize * 0.75
      }
    }
  }

  function filterApps(query) {
    if (query === "") {
      appModel = DesktopEntries.applications.values;
      appList.currentIndex = 0;
      return;
    }
    let results = [];
    let allApps = DesktopEntries.applications.values;
    let lowerQuery = query.toLowerCase();
    for (let i = 0; i < allApps.length; i++) {
      if (allApps[i].name.toLowerCase().indexOf(lowerQuery) !== -1) {
        results.push(allApps[i]);
      }
    }
    appModel = results;
    appList.currentIndex = 0;
  }
}
