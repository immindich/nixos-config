pragma Singleton

import QtQuick
import Quickshell

// Whether to keep the screen awake (no idle dim/lock/suspend from hypridle).
// Toggled from the power menu and shared by every bar; each bar's
// IdleInhibitor follows it. Resets to off when Quickshell restarts or reloads.
Singleton {
    property bool enabled: false
}
