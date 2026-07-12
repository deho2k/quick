pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property alias backgroundOpacity: adapter.backgroundOpacity

  FileView {
    path: Quickshell.statePath("settings.json")
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: adapter
      property real backgroundOpacity: 0.85
    }
  }
}
