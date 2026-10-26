pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pending Flatpak updates (apps and runtimes), checked hourly; a failed check
// (no network yet at login, say) is retried after a minute. `updateAll()`
// installs them; the active user may update without a password, so no
// prompt appears. Without flatpak installed the list just stays empty.
Singleton {
    id: flatpak

    // { name, application, version, branch } for each pending update
    property var updates: []
    readonly property bool checking: check.running
    readonly property bool updating: update.running
    // Last line flatpak printed when the last update failed, otherwise ""
    property string error: ""
    property date checked

    function refresh() {
        if (!check.running && !update.running)
            check.running = true
    }

    function updateAll() {
        if (update.running)
            return
        error = ""
        update.running = true
    }

    Timer {
        interval: 60 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: flatpak.refresh()
    }
    Timer {
        id: retry
        interval: 60 * 1000
        onTriggered: flatpak.refresh()
    }

    // One tab-separated line per update; nothing when up to date
    Process {
        id: check
        command: ["flatpak", "remote-ls", "--updates", "--columns=name,application,version,branch"]
        onExited: exitCode => {
            if (exitCode !== 0) {
                retry.start()
                return
            }
            flatpak.updates = output.text.split("\n").filter(l => l.trim() !== "").map(l => {
                const [name, application, version, branch] = l.split("\t")
                return { name: name || application, application, version: version ?? "", branch: branch ?? "" }
            })
            flatpak.checked = new Date()
        }
        stdout: StdioCollector { id: output }
    }

    Process {
        id: update
        command: ["flatpak", "update", "-y", "--noninteractive"]
        onExited: exitCode => {
            if (exitCode !== 0) {
                const lines = errors.text.trim().split("\n")
                flatpak.error = lines[lines.length - 1] || "Update failed"
            }
            check.running = true
        }
        stderr: StdioCollector { id: errors }
    }
}
