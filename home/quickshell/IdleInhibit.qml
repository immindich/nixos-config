pragma Singleton

import QtQuick
import Quickshell

// Whether to keep the screen awake (no idle dim/lock/suspend from hypridle).
// Shared so every bar shows and toggles the same state; each bar's
// IdleInhibitor follows it. Resets to off when Quickshell restarts or reloads.
Singleton {
    property bool enabled: false
}
