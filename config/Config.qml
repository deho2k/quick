pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property alias adapter: adapter
  property alias backgroundOpacity: adapter.backgroundOpacity
  property alias samsung: adapter.samsung

  FileView {
    id:settingsFile
    path: Quickshell.statePath("settings.json")
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: adapter
      property real backgroundOpacity: 0.85
      property real samsung: 0.85
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
