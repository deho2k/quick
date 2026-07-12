import Quickshell
import QtQuick
import qs.modules
import qs.config
import Quickshell.Hyprland

ShellRoot{
  id:shellRoot

  Pill {id:pill}

  Connections {
    target: Player.player
    ignoreUnknownSignals: true 
    function onIsPlayingChanged()   { pill.showVariant(pill.variant.music) }
    function onPostTrackChanged()   { pill.showVariant(pill.variant.music) }
    function onVolumeChanged()      { pill.showVariant(pill.variant.music) }
  }
  Connections {
    target: Pipewire
    ignoreUnknownSignals: true
    function onVolumeLevelChanged() { pill.showVariant(pill.variant.volume) }
  }
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (Hypr.onEvent(event) == Hypr.event.OpenedSubmap) { pill.changePill(pill.variant.submap) } 
      if (Hypr.onEvent(event) == Hypr.event.ClosedSubmap) { pill.returnToMainPill() } 
    }
  }

  GlobalShortcut {
    name: "show_variant_music" 
    description: "temporarly shows the music osd" 
    onPressed: { pill.showVariant(pill.variant.music) }
  }
  GlobalShortcut {
    name: "toggle_bar" 
    description: "toggles the quickshell pill" 
    onPressed: {
      pill.visible = !pill.visible
    }
  }
  GlobalShortcut {
    name: "toggle_pill" 
    description: "toggles the quickshell pill's big pill" 
    onPressed: {
      pill.togglePillSize()
    }
  }

  GlobalShortcut {
    name: "toggle_search" 
    description: "toggle the search pill" 
    onPressed: {
      pill.changePill(pill.variant.search)
    }
  }
  GlobalShortcut {
    name: "toggle_wallpaper" 
    description: "toggle the search pill" 
    onPressed: {
      pill.changePill(pill.variant.wallpaper)
    }
  }
}
