pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string currentSubmapName: ""
  property alias currentSubmapKeys: keybindModel
  ListModel { id: keybindModel }

  Process {
    id: hyprctlReader
    command: ["hyprctl", "binds", "-j"]
    property string buffer: ""

    stdout: SplitParser { onRead: chunk => { hyprctlReader.buffer += chunk } }

    onRunningChanged: {
      if (running || buffer === "") return

      try {
        const allBinds = JSON.parse(buffer)
        const submapBinds = allBinds.filter(bind => bind.submap === root.currentSubmapName)

        keybindModel.clear()
        for (const bind of submapBinds) {
          keybindModel.append({
            bindKey:     bind.key.toUpperCase(),
            description: bind.description !== ""
            ? bind.description
            : bind.dispatcher + " " + bind.arg
          })
        }
      } catch (parseError) {
        console.error("HyprSubmap: failed to parse hyprctl output:", parseError)
        console.error("Raw buffer:", buffer)
      }
      buffer = ""
    }
  }
  readonly property var event: ({
    OpenedSubmap: 0,
    ClosedSubmap: 1
  })
  function onEvent(event) {
    if (event.name !== "submap") return
    const newSubmapName = event.data

    if (newSubmapName === "") {
      root.currentSubmapName = ""
      keybindModel.clear()
      return root.event.ClosedSubmap
    }

    root.currentSubmapName = newSubmapName
    keybindModel.clear()
    hyprctlReader.running = false
    hyprctlReader.buffer  = ""
    hyprctlReader.running = true
    return root.event.OpenedSubmap
  }
}

