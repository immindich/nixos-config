pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The laptop backlight's raw brightness (`current` out of `max`), kept up to
// date for the bar indicator, brightness menu and OSD
Singleton {
    readonly property int max: parseInt(maxBrightnessFile.text())
    readonly property int current: parseInt(brightnessFile.text())
    readonly property int percent: max > 0 ? Math.floor(current / max * 100) : 0

    FileView { id: brightnessFile; path: "/sys/class/backlight/intel_backlight/brightness" }
    FileView { id: maxBrightnessFile; path: "/sys/class/backlight/intel_backlight/max_brightness" }

    // sysfs doesn't send file change notifications, but the kernel announces
    // backlight changes as udev events (this is how ashell does it). Each line
    // udevadm prints means something may have changed, so re-read the file.
    Process {
        id: backlightMonitor
        running: true
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        stdout: SplitParser {
            onRead: brightnessFile.reload()
        }
        // Restart it if it exits or fails to start, after a cooldown so a
        // broken command doesn't run in a tight loop
        onRunningChanged: if (!running) backlightRestart.start()
    }
    Timer {
        id: backlightRestart
        interval: 5000
        onTriggered: {
            brightnessFile.reload() // catch changes missed while it was down
            backlightMonitor.running = true
        }
    }
}
