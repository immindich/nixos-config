import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// Bluetooth on/off switch and paired devices with connect/disconnect buttons
// and battery levels, shown when the control center's Bluetooth tile is
// expanded. Pairing new devices isn't handled here.
Column {
    id: bluetoothSection

    width: parent.width - parent.leftPadding - parent.rightPadding
    spacing: Theme.px(8)

    readonly property var adapter: Bluetooth.defaultAdapter

    Item {
        width: parent.width
        implicitHeight: Math.max(enabledLabel.implicitHeight, bluetoothSwitch.implicitHeight)

        Text {
            id: enabledLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Bluetooth"
            font.pixelSize: Theme.fontSize
            color: Theme.dimTextColor
        }

        MenuSwitch {
            id: bluetoothSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            enabled: bluetoothSection.adapter !== null
            checked: bluetoothSection.adapter?.enabled ?? false
            onToggled: bluetoothSection.adapter.enabled = !bluetoothSection.adapter.enabled
        }
    }

    Text {
        visible: bluetoothSection.adapter === null || (bluetoothSection.adapter.enabled && devices.count === 0)
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
        text: bluetoothSection.adapter === null ? "No Bluetooth adapter" : "No paired devices"
    }

    Column {
        visible: bluetoothSection.adapter?.enabled ?? false
        width: parent.width
        spacing: Theme.px(2)

        Repeater {
            id: devices

            // Connected devices first, then by name
            model: ScriptModel {
                values: (bluetoothSection.adapter?.devices.values ?? [])
                    .filter(d => d.paired)
                    .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
            }

            DeviceEntry {}
        }
    }

    component DeviceEntry: Rectangle {
        id: entry
        required property var modelData
        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting
            || modelData.state === BluetoothDeviceState.Disconnecting

        width: parent.width
        height: Theme.px(36)
        radius: Theme.px(8)
        color: "transparent"

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.px(8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.px(8)

            // Device type from BlueZ's icon name, e.g. "audio-headset"
            Text {
                id: typeIcon
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.px(18)
                horizontalAlignment: Text.AlignHCenter
                readonly property string kind: entry.modelData.icon
                text: kind.startsWith("audio-head") ? "\uf025"   // headphones
                    : kind.startsWith("audio") ? "\uf8df"        // speaker
                    : kind === "input-keyboard" ? "\uf11c"       // keyboard
                    : kind === "input-mouse" ? "\uf8cc"          // computer-mouse
                    : kind === "input-gaming" ? "\uf11b"         // gamepad
                    : kind === "phone" ? "\uf3cd"                // mobile-screen
                    : kind === "computer" ? "\uf109"             // laptop
                    : "\uf294"                                   // bluetooth-b
                font.family: text === "\uf294" ? Theme.brandIconFont : Theme.iconFont
                font.weight: Font.Black
                font.pixelSize: Theme.iconSize
                color: entry.modelData.connected ? Theme.selectedText : Theme.textColor
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                // Whatever space the right side leaves
                width: Math.min(implicitWidth, entry.width - Theme.px(8) - typeIcon.width - Theme.px(8 + 12) - actions.width - Theme.px(8))
                elide: Text.ElideRight
                text: entry.modelData.name
                textFormat: Text.PlainText
                font.pixelSize: Theme.fontSize
                font.bold: entry.modelData.connected
                color: entry.modelData.connected ? Theme.selectedText : Theme.textColor
            }
        }

        Row {
            id: actions
            anchors.right: parent.right
            anchors.rightMargin: Theme.px(8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.px(8)

            // Battery level, if the device reports it
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                visible: entry.modelData.batteryAvailable
                text: Math.round(entry.modelData.battery * 100) + "%"
                font.pixelSize: Theme.fontSize - Theme.px(2)
                color: entry.modelData.battery <= 0.15 ? Theme.bad : Theme.dimTextColor
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                visible: entry.busy
                text: entry.modelData.state === BluetoothDeviceState.Connecting ? "Connecting…" : "Disconnecting…"
                font.pixelSize: Theme.fontSize - Theme.px(2)
                color: Theme.dimTextColor
            }

            // Connect / Disconnect button
            PillButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: !entry.busy
                height: Theme.px(22)
                horizontalPadding: Theme.px(8)
                text: entry.modelData.connected ? "Disconnect" : "Connect"
                onClicked: {
                    if (entry.modelData.connected)
                        entry.modelData.disconnect()
                    else
                        entry.modelData.connect()
                }
            }
        }
    }
}
