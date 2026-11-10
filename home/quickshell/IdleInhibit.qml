pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Whether to keep the screen awake (no idle dim/lock/suspend from hypridle).
// Toggled from the power menu and shared by every bar. Resets to off when
// Quickshell restarts or reloads.
Singleton {
    id: root

    property bool enabled: false

    // Held as a logind idle inhibitor: hypridle ignores Wayland ones and
    // leaves those to screensaver-inhibit (home/hypridle.nix), which only
    // sees windows. The power menu leaves this one out of its list by its
    // who. setpriv ends it if Quickshell dies without stopping it.
    Process {
        running: root.enabled
        command: ["setpriv", "--pdeathsig", "TERM", "--",
            "systemd-inhibit", "--what=idle", "--who=quickshell", "--why=Keep awake switch",
            "sleep", "infinity"]
    }
}
