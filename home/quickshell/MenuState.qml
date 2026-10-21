pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Tracks the open DropdownMenu so only one is open at a time, and closes it
// when the focused workspace changes (including toggling a special one)
Singleton {
    property var openMenu: null

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
