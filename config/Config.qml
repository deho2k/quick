pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property alias adapter: adapter
  property alias hyprland: adapter.hyprland
  property alias general: adapter.general

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
      }
      property JsonObject hyprland: JsonObject {
        property int borderSize: 2
        property bool animations: true
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
}
