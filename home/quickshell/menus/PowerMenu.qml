import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import qs

// Battery details, the keep-awake switch with what else is blocking idle,
// and the power profile switcher, opened from the battery indicator. Set
// `anchor.item` to the indicator.
DropdownMenu {
    id: powerMenu

    // The combined battery UPower reports; health is only on the physical
    // battery itself
    readonly property var battery: UPower.displayDevice
    readonly property var laptopBattery: UPower.devices.values.find(d => d.isLaptopBattery) ?? null

    // What else is keeping the screen awake, as { who, why }: windows holding
    // a Wayland idle inhibitor (Hyprland reports them, but not why), and
    // logind idle inhibitors (systemd-inhibit --what=idle). hypridle honors
    // both. Inhibits made over D-Bus (org.freedesktop.ScreenSaver, e.g.
    // Firefox) are among the logind ones: screensaver-inhibit turns each
    // into a logind inhibitor with the app and reason.
    property var logindBlockers: []
    readonly property var blockers: Hyprland.toplevels.values
        .filter(t => t.lastIpcObject?.inhibitingIdle)
        .map(t => ({ who: t.lastIpcObject.class || t.title, why: t.title }))
        .concat(logindBlockers)

    // Neither source announces changes, so poll while the menu is open
    function refreshBlockers() {
        Hyprland.refreshToplevels()
        logindInhibitors.running = true
    }
    onVisibleChanged: if (visible) refreshBlockers()
    Timer {
        running: powerMenu.visible
        repeat: true
        interval: 2000
        onTriggered: powerMenu.refreshBlockers()
    }

    Process {
        id: logindInhibitors
        command: ["busctl", "--json=short", "call", "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", "ListInhibitors"]
        stdout: StdioCollector {
            // Each entry is [what, who, why, mode, uid, pid]; `what` is a
            // colon-separated list such as "sleep:idle"
            onStreamFinished: {
                try {
                    powerMenu.logindBlockers = JSON.parse(text).data[0]
                        .filter(i => i[0].split(":").includes("idle"))
                        .map(i => ({ who: i[1], why: i[2] }))
                } catch (e) {
                    powerMenu.logindBlockers = []
                }
            }
        }
    }

    // "2 h 5 min" / "35 min"
    function formatDuration(seconds) {
        const minutes = Math.round(seconds / 60)
        const hours = Math.floor(minutes / 60)
        return hours > 0 ? hours + " h " + (minutes % 60) + " min" : minutes + " min"
    }

    MenuHeading { text: "Power" }

    MenuInfoRow {
        label: "Charge"
        value: Math.round(powerMenu.battery.percentage * 100) + "%"
    }
    MenuInfoRow {
        label: "Status"
        value: powerMenu.battery.state === UPowerDeviceState.Charging ? "Charging"
            : powerMenu.battery.state === UPowerDeviceState.Discharging ? "Discharging"
            : powerMenu.battery.state === UPowerDeviceState.FullyCharged ? "Fully charged"
            : powerMenu.battery.state === UPowerDeviceState.PendingCharge ? "Not charging"
            : powerMenu.battery.state === UPowerDeviceState.Empty ? "Empty"
            : "Unknown"
    }
    MenuInfoRow {
        readonly property bool toFull: powerMenu.battery.state === UPowerDeviceState.Charging
        readonly property real seconds: toFull ? powerMenu.battery.timeToFull : powerMenu.battery.timeToEmpty
        visible: seconds > 0
        label: toFull ? "Until full" : "Time left"
        value: powerMenu.formatDuration(seconds)
    }
    MenuInfoRow {
        visible: powerMenu.battery.changeRate !== 0
        label: powerMenu.battery.changeRate > 0 ? "Charging at" : "Power draw"
        value: Math.abs(powerMenu.battery.changeRate).toFixed(1) + " W"
    }
    MenuInfoRow {
        label: "Energy"
        value: powerMenu.battery.energy.toFixed(1) + " / " + powerMenu.battery.energyCapacity.toFixed(1) + " Wh"
    }
    MenuInfoRow {
        visible: powerMenu.laptopBattery?.healthSupported ?? false
        label: "Health"
        value: Math.round(powerMenu.laptopBattery?.healthPercentage ?? 0) + "%"
    }

    Item {
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: Math.max(keepAwakeHeading.implicitHeight, keepAwakeSwitch.implicitHeight)

        MenuHeading {
            id: keepAwakeHeading
            anchors.verticalCenter: parent.verticalCenter
            text: "Keep awake"
        }

        MenuSwitch {
            id: keepAwakeSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: IdleInhibit.enabled
            onToggled: IdleInhibit.enabled = !IdleInhibit.enabled
        }
    }

    Text {
        visible: powerMenu.blockers.length === 0
        text: "Nothing else is blocking idle"
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
    }

    Text {
        visible: powerMenu.blockers.length > 0
        text: "Also blocking idle:"
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
    }

    // Name, then the reason in smaller dim text
    Repeater {
        model: powerMenu.blockers

        Column {
            id: blocker
            required property var modelData
            width: parent.width - parent.leftPadding - parent.rightPadding

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: blocker.modelData.who
                textFormat: Text.PlainText
                font.pixelSize: Theme.fontSize
                color: Theme.textColor
            }

            Text {
                visible: text !== ""
                width: parent.width
                elide: Text.ElideRight
                text: blocker.modelData.why
                textFormat: Text.PlainText
                font.pixelSize: Theme.fontSize - 2
                color: Theme.dimTextColor
            }
        }
    }

    MenuHeading { text: "Power profile" }
    PowerProfileSelector {}
}
