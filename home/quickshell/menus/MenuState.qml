pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Tracks the open DropdownMenu so only one is open at a time, and closes it
// when the focused workspace changes (including toggling a special one)
Singleton {
    id: root

    property var openMenu: null

    // While set, menus stay open when something else takes focus, so a
    // screenshot tool like slurp can capture them. Set it by hand over IPC:
    // `qs ipc call menus hold true`, then `false` when done.
    property bool hold: false

    IpcHandler {
        target: "menus"
        function hold(on: bool): void { root.hold = on }
    }

    function closeMenu() {
        if (openMenu)
            openMenu.visible = false
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { closeMenu() }
        function onRawEvent(event) {
            if (event.name === "activespecial")
                closeMenu()
        }
    }
}
