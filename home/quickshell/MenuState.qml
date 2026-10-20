pragma Singleton

import QtQuick
import Quickshell

// Tracks the open DropdownMenu so only one is open at a time
Singleton {
    property var openMenu: null
}
