pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
  id: root
  PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }
  readonly property real volumeLevel: Pipewire.defaultAudioSink?.audio?.volume ?? 0.0
}

