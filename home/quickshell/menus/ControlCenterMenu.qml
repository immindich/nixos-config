import QtQuick
import Quickshell.Bluetooth
import qs

// Opened from the control center indicator; set `anchor.item` to it. From
// the top: media controls (while a player is running), the brightness slider
// (with a backlight), and tiles for Bluetooth and night light, whose chevrons
// show their details below the tiles, one at a time. The Bluetooth tile is
// filled while a device is connected, and clicking it shows the on/off
// switch and paired devices; the night light tile is filled while it's on,
// and clicking it turns it on or off. A do-not-disturb tile (no details)
// follows them.
// Parts with nothing to control are hidden.
DropdownMenu {
    id: controlCenter

    menuWidth: Theme.px(320)

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool hasMedia: Media.player !== null
    readonly property bool hasBrightness: Brightness.max > 0
    readonly property bool hasBluetooth: adapter !== null
    readonly property bool hasNightLight: NightLight.available
    // Connected devices, for the Bluetooth tile's status
    readonly property var connectedDevices: (adapter?.devices.values ?? []).filter(d => d.connected)

    // Which tile's details are shown: "", "bluetooth" or "nightLight"
    property string expanded: ""

    function toggleExpanded(name) {
        expanded = expanded === name ? "" : name
    }

    onVisibleChanged: if (!visible) expanded = ""

    component Divider: Rectangle {
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: Theme.px(1)
        color: Theme.borderColor
    }

    MediaSection {
        visible: controlCenter.hasMedia
        shown: controlCenter.visible
    }

    Divider { visible: controlCenter.hasMedia }

    BrightnessSection { visible: controlCenter.hasBrightness }

    // Two to a row; with an odd number, the last (do-not-disturb) spans the row
    Flow {
        id: tiles
        width: parent.width - parent.leftPadding - parent.rightPadding
        spacing: Theme.px(8)

        readonly property int count: (controlCenter.hasBluetooth ? 1 : 0) + (controlCenter.hasNightLight ? 1 : 0) + 1
        readonly property real tileWidth: (width - spacing) / 2

        QuickToggle {
            visible: controlCenter.hasBluetooth
            width: tiles.tileWidth
            icon: "\uf294" // bluetooth-b
            iconFont: Theme.brandIconFont
            label: "Bluetooth"
            status: !(controlCenter.adapter?.enabled ?? false) ? "Off"
                : controlCenter.connectedDevices.length === 1 ? controlCenter.connectedDevices[0].name
                : controlCenter.connectedDevices.length > 1 ? controlCenter.connectedDevices.length + " devices"
                : "On"
            // Filled while a device is connected; on/off is in the details
            checked: controlCenter.connectedDevices.length > 0
            expanded: controlCenter.expanded === "bluetooth"
            onToggled: controlCenter.toggleExpanded("bluetooth")
            onExpandToggled: controlCenter.toggleExpanded("bluetooth")
        }

        QuickToggle {
            visible: controlCenter.hasNightLight
            width: tiles.tileWidth
            icon: "\uf186" // moon
            label: "Night light"
            status: !NightLight.enabled ? "Off"
                : NightLight.active ? NightLight.appliedTemperature + " K"
                : NightLight.auto ? "At " + Qt.formatTime(NightLight.next.time, "h:mm ap")
                : "On"
            checked: NightLight.enabled
            expanded: controlCenter.expanded === "nightLight"
            onToggled: NightLight.enabled = !NightLight.enabled
            onExpandToggled: controlCenter.toggleExpanded("nightLight")
        }

        QuickToggle {
            width: tiles.count % 2 === 1 ? tiles.width : tiles.tileWidth
            icon: "\uf1f6" // bell-slash
            label: "Do not disturb"
            status: Notifications.dnd ? "On" : "Off"
            checked: Notifications.dnd
            expandable: false
            onToggled: Notifications.dnd = !Notifications.dnd
        }
    }

    BluetoothSection { visible: controlCenter.hasBluetooth && controlCenter.expanded === "bluetooth" }

    NightLightSection { visible: controlCenter.hasNightLight && controlCenter.expanded === "nightLight" }
}
