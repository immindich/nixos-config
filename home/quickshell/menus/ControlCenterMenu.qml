import QtQuick
import Quickshell.Bluetooth
import qs

// Opened from the control center indicator; set `anchor.item` to it. From
// the top: media controls (while a player is running), the brightness slider
// (with a backlight), and tiles for Bluetooth and night light. A tile turns
// its setting on and off, and its chevron shows the details below the tiles
// (paired devices; night light schedule and temperature), one at a time.
// Parts with nothing to control are hidden.
DropdownMenu {
    id: controlCenter

    menuWidth: Theme.px(320)

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool hasMedia: Media.player !== null
    readonly property bool hasBrightness: Brightness.max > 0
    readonly property bool hasBluetooth: adapter !== null
    readonly property bool hasNightLight: NightLight.available
    readonly property bool hasTiles: hasBluetooth || hasNightLight
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

    Divider { visible: controlCenter.hasMedia && (controlCenter.hasBrightness || controlCenter.hasTiles) }

    BrightnessSection { visible: controlCenter.hasBrightness }

    Row {
        id: tiles
        visible: controlCenter.hasTiles
        width: parent.width - parent.leftPadding - parent.rightPadding
        spacing: Theme.px(8)

        // Shared evenly between the tiles shown
        readonly property int count: (controlCenter.hasBluetooth ? 1 : 0) + (controlCenter.hasNightLight ? 1 : 0)
        readonly property real tileWidth: (width - spacing * (count - 1)) / Math.max(count, 1)

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
            checked: controlCenter.adapter?.enabled ?? false
            expanded: controlCenter.expanded === "bluetooth"
            onToggled: controlCenter.adapter.enabled = !controlCenter.adapter.enabled
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
    }

    BluetoothSection { visible: controlCenter.hasBluetooth && controlCenter.expanded === "bluetooth" }

    NightLightSection { visible: controlCenter.hasNightLight && controlCenter.expanded === "nightLight" }

    Text {
        visible: !controlCenter.hasMedia && !controlCenter.hasBrightness && !controlCenter.hasTiles
        text: "Nothing to control"
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
    }
}
