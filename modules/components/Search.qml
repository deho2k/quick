import Quickshell
import QtQuick
import Quickshell.Wayland
import qs.config
import qs.widgets

PillBase {
  id: content
  implicitWidth: container.implicitWidth + 20
  implicitHeight: container.implicitHeight + 20


  property var appModel: DesktopEntries.applications.values
  readonly property int rowHeight: 60
  readonly property int rowSpacing: 2
  readonly property int maxVisibleRows: 6

  Column {
    id: container
    anchors.centerIn: parent
    spacing: 4

    Rectangle {
      id: searchBox
      color: Colors.primary
      radius: 5
      height: 20
      width: 600
      TextInput {
        id: searchInput
        anchors.fill: parent
        onTextChanged: content.filterApps(text)
        Keys.onPressed: (event) => {
          if (event.key === Qt.Key_Down) { appList.incrementCurrentIndex() }
          else if (event.key === Qt.Key_Up) { appList.decrementCurrentIndex() }
        }
        Keys.onReturnPressed: {
          appList.currentItem.modelData.execute()
          content.returnToMainPill()
        }
        Component.onCompleted: { searchInput.forceActiveFocus(); }
      }
    }

    Rectangle {
      id: listWrapper
      color: "transparent"
      anchors.left: parent.left
      anchors.right: parent.right
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
          required property var modelData
          anchors.left: parent.left; anchors.right: parent.right
          height: content.rowHeight
          color: ListView.isCurrentItem ? Colors.outline_variant : "transparent"
          radius: 4
          Image {
            id: appIcon
            cache: true
            source: parent.modelData.icon ? "image://icon/" + parent.modelData.icon : ""
            width: 32
            height: 32
            fillMode: Image.PreserveAspectFit
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
          }
          StyledText {
            text: parent.modelData.name
            font.pixelSize: 16
            anchors.left: appIcon.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }
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
