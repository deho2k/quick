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
    path: Quickshell.env("HOME") + "/.config/quickshell/config/json/settings.json"
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: adapter
      // page
      property JsonObject general: JsonObject {
        // properties inside the page
        property int backgroundOpacity: 85
        property int radius: 8
        property int fontSize: 20
      }
      property JsonObject position: JsonObject {
        property int margins: 5
        property bool top: true; property bool bottom: false
        property bool right: false; property bool left: false
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
