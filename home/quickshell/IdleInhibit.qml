pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Whether to keep the screen awake (no idle dim/lock/suspend from hypridle).
// Toggled from the power menu and shared by every bar. Kept across config
// reloads; resets to off when Quickshell restarts.
Singleton {
    id: root

    property alias enabled: persist.enabled

    PersistentProperties {
        id: persist
        reloadableId: "idleInhibit"
        property bool enabled: false
    }

    // Held as a logind idle inhibitor: hypridle ignores Wayland ones and
    // leaves those to screensaver-inhibit (home/hypridle.nix), which only
    // sees windows. The power menu leaves this one out of its list by its
    // who. setpriv ends it if Quickshell dies without stopping it. A reload
    // replaces the process, leaving about 50 ms with no inhibitor; hypridle
    // then restarts its idle timers instead of firing overdue ones, so that
    // can't dim, lock or suspend.
    Process {
        running: root.enabled
        command: ["setpriv", "--pdeathsig", "TERM", "--",
            "systemd-inhibit", "--what=idle", "--who=quickshell", "--why=Keep awake switch",
            "sleep", "infinity"]
    }
}
