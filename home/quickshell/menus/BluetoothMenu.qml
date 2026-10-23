import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// Bluetooth on/off switch and paired devices with connect/disconnect buttons
// and battery levels, opened from the Bluetooth indicator. Set `anchor.item`
// to the indicator. Pairing new devices isn't handled here.
DropdownMenu {
    id: bluetoothMenu

    readonly property var adapter: Bluetooth.defaultAdapter

    // Wider than the default to fit name, battery level and button on one line
    implicitWidth: 320

    Item {
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: Math.max(heading.implicitHeight, bluetoothSwitch.implicitHeight)

        MenuHeading {
            id: heading
            anchors.verticalCenter: parent.verticalCenter
            text: "Bluetooth"
        }

        MenuSwitch {
            id: bluetoothSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            enabled: bluetoothMenu.adapter !== null
            checked: bluetoothMenu.adapter?.enabled ?? false
            onToggled: bluetoothMenu.adapter.enabled = !bluetoothMenu.adapter.enabled
        }
    }

    Text {
        visible: !(bluetoothMenu.adapter?.enabled ?? false) || devices.count === 0
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
        text: bluetoothMenu.adapter === null ? "No Bluetooth adapter"
            : !bluetoothMenu.adapter.enabled ? "Bluetooth is off"
            : "No paired devices"
    }

    Column {
        visible: bluetoothMenu.adapter?.enabled ?? false
        width: parent.width - parent.leftPadding - parent.rightPadding
        spacing: 2

        Repeater {
            id: devices

            // Connected devices first, then by name
            model: ScriptModel {
                values: (bluetoothMenu.adapter?.devices.values ?? [])
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
        height: 36
        radius: 8
        color: "transparent"

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Device type from BlueZ's icon name, e.g. "audio-headset"
            Text {
                id: typeIcon
                anchors.verticalCenter: parent.verticalCenter
                width: 18
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
                color: entry.modelData.connected ? Theme.accent : Theme.textColor
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                // Whatever space the right side leaves
                width: Math.min(implicitWidth, entry.width - 8 - typeIcon.width - 8 - 12 - actions.width - 8)
                elide: Text.ElideRight
                text: entry.modelData.name
                textFormat: Text.PlainText
                font.pixelSize: Theme.fontSize
                font.bold: entry.modelData.connected
                color: entry.modelData.connected ? Theme.accent : Theme.textColor
            }
        }

        Row {
            id: actions
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Battery level, if the device reports it
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                visible: entry.modelData.batteryAvailable
                text: Math.round(entry.modelData.battery * 100) + "%"
                font.pixelSize: Theme.fontSize - 2
                color: entry.modelData.battery <= 0.15 ? Theme.bad : Theme.dimTextColor
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                visible: entry.busy
                text: entry.modelData.state === BluetoothDeviceState.Connecting ? "Connecting…" : "Disconnecting…"
                font.pixelSize: Theme.fontSize - 2
                color: Theme.dimTextColor
            }

            // Connect / Disconnect button
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: !entry.busy
                width: buttonLabel.implicitWidth + 16
                height: 22
                radius: height / 2
                color: buttonHover.hovered ? Theme.highlight : Theme.surface

                Text {
                    id: buttonLabel
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Theme.textOffset
                    text: entry.modelData.connected ? "Disconnect" : "Connect"
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.textColor
                }

                HoverHandler { id: buttonHover }
                TapHandler {
                    onTapped: {
                        if (entry.modelData.connected)
                            entry.modelData.disconnect()
                        else
                            entry.modelData.connect()
                    }
                }
            }
        }
    }
}
