pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property alias adapter: adapter
  property alias general: adapter.general
  property alias position: adapter.position

  FileView {
    id:settingsFile
    path: Quickshell.statePath("settings.json")
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: adapter
      property JsonObject general: JsonObject {
        property real backgroundOpacity: 0.85
        property bool samsung: true
        property int radius: 8
        property int fontSize: 20
      }
      property JsonObject position: JsonObject {
        property bool top: true; property bool bottom: false
        property bool right: false; property bool left: false
        property int margins: 5
      }
    }
  }

  readonly property var settingsKeys: {
    try {
      let parsed = settingsFile.text() ? JSON.parse(settingsFile.text()) : {};
      return Object.keys(parsed);
    } catch (e) {
      return [];
    }
  }
  function keysForPage(page) {
    if (settingsKeys.length === 0) return [];
    const category = settingsKeys[((page % settingsKeys.length) + settingsKeys.length) % settingsKeys.length];
    const obj = adapter[category];
    return Object.keys(obj).filter(key => {
      const val = obj[key];
      return (typeof val === "boolean" || typeof val === "number");
    });
  }
}
