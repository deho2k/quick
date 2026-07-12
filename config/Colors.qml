pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Io
Singleton {
  id:root
  IpcHandler {
    target: "colors"
    function reload() {
      root.updateColors()
    }
  }
  function updateColors() {
    readProcess.running = true;
  }
  Process {
    id: readProcess
    command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/config/json/matugen.json"]
    running: false
    property string buffer: ""
    stdout: SplitParser {
      onRead: data => {
        readProcess.buffer += data
      }
    }
    onRunningChanged: {
      if (!running && buffer !== "") {
        try {
          let colorObj = JSON.parse(buffer)
          for (let key in colorObj) {
            if (Colors.hasOwnProperty(key)) {
              Colors[key] = colorObj[key]
            }
          }
          console.log("Colors reloaded successfully - " + Object.keys(colorObj).length + " colors updated")
        } catch (e) {
          console.error("Failed to parse matugen colors.json:", e)
          console.error("Buffer content:", buffer)
        } finally {
          buffer = ""
        }
      }
    }
  }
  property color background: "#141315"
  property color error: "#ffb4ab"
  property color error_container: "#93000a"
  property color inverse_on_surface: "#313032"
  property color inverse_primary: "#5f5c6c"
  property color inverse_surface: "#e5e1e3"
  property color on_background: "#e5e1e3"
  property color on_error: "#690005"
  property color on_error_container: "#ffdad6"
  property color on_primary: "#312f3c"
  property color on_primary_container: "#e5e0f2"
  property color on_primary_fixed: "#1c1a27"
  property color on_primary_fixed_variant: "#474553"
  property color on_secondary: "#312f38"
  property color on_secondary_container: "#e5e0ec"
  property color on_secondary_fixed: "#1c1b22"
  property color on_secondary_fixed_variant: "#48464f"
  property color on_surface: "#e5e1e3"
  property color on_surface_variant: "#c9c5c7"
  property color on_tertiary: "#312e41"
  property color on_tertiary_container: "#e5dff9"
  property color on_tertiary_fixed: "#1c192c"
  property color on_tertiary_fixed_variant: "#474459"
  property color outline: "#939092"
  property color outline_variant: "#484648"
  property color primary: "#c9c4d6"
  property color primary_container: "#474553"
  property color primary_fixed: "#e5e0f2"
  property color primary_fixed_dim: "#c9c4d6"
  property color scrim: "#000000"
  property color secondary: "#c9c5d0"
  property color secondary_container: "#48464f"
  property color secondary_fixed: "#e5e0ec"
  property color secondary_fixed_dim: "#c9c5d0"
  property color shadow: "#000000"
  property color source_color: "#735cfa"
  property color surface: "#141315"
  property color surface_bright: "#3a393a"
  property color surface_container: "#201f21"
  property color surface_container_high: "#2b2a2b"
  property color surface_container_highest: "#353436"
  property color surface_container_low: "#1c1b1d"
  property color surface_container_lowest: "#0e0e0f"
  property color surface_dim: "#141315"
  property color surface_tint: "#c9c4d6"
  property color surface_variant: "#484648"
  property color tertiary: "#c8c3dc"
  property color tertiary_container: "#474459"
  property color tertiary_fixed: "#e5dff9"
  property color tertiary_fixed_dim: "#c8c3dc"
  property string image: ""
  Component.onCompleted: { readProcess.running = true }
}
