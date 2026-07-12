pragma Singleton

import Quickshell
import Quickshell.Services.Mpris 
import QtQuick

Singleton {
  id: root
  property var player: {
    const players = Mpris.players.values;
    return players.find(p => p.identity === "Spotify") ?? 
    players.find(p => p.identity === "mpc" || p.identity === "mpd") ?? 
    (players.length > 0 ? players[0] : null);
  }
}

