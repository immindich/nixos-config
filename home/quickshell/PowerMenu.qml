import QtQuick
import Quickshell.Services.UPower

// Battery details and power profile switcher, opened from the battery
// indicator. Set `anchor.item` to the indicator.
DropdownMenu {
    id: powerMenu

    // The combined battery UPower reports; health is only on the physical
    // battery itself
    readonly property var battery: UPower.displayDevice
    readonly property var laptopBattery: UPower.devices.values.find(d => d.isLaptopBattery) ?? null

    // "2 h 5 min" / "35 min"
    function formatDuration(seconds) {
        const minutes = Math.round(seconds / 60)
        const hours = Math.floor(minutes / 60)
        return hours > 0 ? hours + " h " + (minutes % 60) + " min" : minutes + " min"
    }

    MenuHeading { text: "Power" }

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

    MenuHeading { text: "Power profile" }
    PowerProfileSelector {}
}
