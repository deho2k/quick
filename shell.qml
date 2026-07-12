import Quickshell
import QtQuick
import qs.modules
import qs.config
import Quickshell.Hyprland

ShellRoot{
  id:shellRoot

  Bar{id:bar;}

  Connections {
    target: Player.player
    ignoreUnknownSignals: true 
    function onIsPlayingChanged()   { bar.showVariant(bar.variant.music) }
    function onPostTrackChanged()   { bar.showVariant(bar.variant.music) }
    function onVolumeChanged()      { bar.showVariant(bar.variant.music) }
  }
  Connections {
    target: Pipewire
    ignoreUnknownSignals: true
    function onVolumeLevelChanged() { bar.showVariant(bar.variant.volume) }
  }
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (Hypr.onEvent(event) == Hypr.event.OpenedSubmap) { bar.changePill(bar.variant.submap) } 
      if (Hypr.onEvent(event) == Hypr.event.ClosedSubmap) { bar.returnToMainPill() } 
    }
  }

  GlobalShortcut {
    name: "show_variant_music" 
    description: "temporarly shows the music osd" 
    onPressed: { bar.showVariant(bar.variant.music) }
  }
  GlobalShortcut {
    name: "toggle_bar" 
    description: "toggles the quickshell bar" 
    onPressed: {
      bar.visible = !bar.visible
    }
  }
  GlobalShortcut {
    name: "toggle_pill" 
    description: "toggles the quickshell bar's big pill" 
    onPressed: {
      bar.togglePillSize()
    }
  }

  GlobalShortcut {
    name: "toggle_search" 
    description: "toggle the search bar" 
    onPressed: {
      bar.changePill(bar.variant.search)
    }
  }
  GlobalShortcut {
    name: "toggle_wallpaper" 
    description: "toggle the search bar" 
    onPressed: {
      bar.changePill(bar.variant.wallpaper)
    }
  }
}
