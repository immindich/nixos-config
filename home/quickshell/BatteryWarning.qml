import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Notifies when the battery runs low while discharging, and again (as
// critical, in its place) when it's nearly empty. Each level fires once per
// discharge; plugging in the charger withdraws the notification. It's sent
// over D-Bus like any app's, since the shell's own server can't be posted to
// directly.
Scope {
    id: root

    property int lowPercent: 15
    property int criticalPercent: 5

    readonly property var battery: UPower.displayDevice
    readonly property int percent: Math.round(battery.percentage * 100)
    readonly property bool discharging: battery.isLaptopBattery
        && battery.state === UPowerDeviceState.Discharging

    // Survives QML reloads, as the notification itself does, so a reload
    // neither posts it again nor loses the id needed to close it
    PersistentProperties {
        id: persist
        reloadableId: "batteryWarning"
        // 0 none, 1 low, 2 critical
        property int notifiedLevel: 0
        property int notificationId: 0
    }

    onPercentChanged: check()
    onDischargingChanged: check()
    Component.onCompleted: check()

    function check() {
        if (!discharging) {
            persist.notifiedLevel = 0
            close()
            return
        }
        const level = percent <= criticalPercent ? 2 : percent <= lowPercent ? 1 : 0
        if (level > persist.notifiedLevel && !notify.running) {
            persist.notifiedLevel = level
            send(level)
        }
    }

    // A replaced notification wouldn't pop up again, so the critical one
    // closes the low one and is posted fresh
    function send(level) {
        close()
        const minutes = Math.round(battery.timeToEmpty / 60)
        const body = percent + "% remaining" + (minutes > 0 ? " (about " + minutes + " min)" : "")
        notify.command = [
            "busctl", "--user", "call", "--",
            "org.freedesktop.Notifications", "/org/freedesktop/Notifications",
            "org.freedesktop.Notifications", "Notify", "susssasa{sv}i",
            "Battery", "0", "battery-caution",
            level === 2 ? "Battery critically low" : "Battery low", body,
            "0", "1", "urgency", "y", String(level), "-1"
        ]
        notify.running = true
    }

    function close() {
        if (persist.notificationId === 0 || notify.running)
            return
        closer.command = [
            "busctl", "--user", "call", "--",
            "org.freedesktop.Notifications", "/org/freedesktop/Notifications",
            "org.freedesktop.Notifications", "CloseNotification", "u",
            String(persist.notificationId)
        ]
        closer.running = true
        persist.notificationId = 0
    }

    // Replies "u <id>"
    Process {
        id: notify
        stdout: StdioCollector {
            onStreamFinished: {
                const id = parseInt(text.trim().split(" ")[1])
                if (id > 0)
                    persist.notificationId = id
            }
        }
        // The charger may have been plugged in, or the next level reached,
        // while the call was in flight
        onExited: Qt.callLater(root.check)
    }

    Process {
        id: closer
    }
}
