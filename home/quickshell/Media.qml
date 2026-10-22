pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player the bar shows: whichever one is playing, otherwise the
// last one that was (as long as it's still running), otherwise the first.
// Null when no player is running.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property var player: null

    function pick() {
        const playing = players.find(p => p.isPlaying)
        if (playing)
            player = playing
        else if (!players.includes(player))
            player = players[0] ?? null
    }

    onPlayersChanged: pick()

    // A player starting to play takes over from the current one
    Instantiator {
        model: Mpris.players

        Connections {
            required property var modelData
            target: modelData
            function onIsPlayingChanged() { root.pick() }
        }
    }
}
