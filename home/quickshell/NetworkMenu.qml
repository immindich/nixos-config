import QtQuick
import Quickshell
import Quickshell.Networking

// Wi-Fi network selector, opened from the network indicator. Set
// `anchor.item` to the indicator. Click a network to connect; if it needs a
// password NetworkManager doesn't have yet, a password field opens below it.
DropdownMenu {
    id: networkMenu
    // For the password field
    takesKeyboard: true

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    // Scan for networks only while the menu is open
    Binding {
        target: networkMenu.wifiDevice
        property: "scannerEnabled"
        value: networkMenu.visible
        when: networkMenu.wifiDevice !== null
    }

    Item {
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: Math.max(heading.implicitHeight, wifiSwitch.implicitHeight)

        MenuHeading {
            id: heading
            anchors.verticalCenter: parent.verticalCenter
            text: "Wi-Fi"
        }

        // Software on/off; disabled while a hardware switch blocks Wi-Fi
        MenuSwitch {
            id: wifiSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            enabled: Networking.wifiHardwareEnabled
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    Text {
        visible: !Networking.wifiEnabled || networkMenu.wifiDevice === null
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
        text: networkMenu.wifiDevice === null ? "No Wi-Fi device"
            : !Networking.wifiHardwareEnabled ? "Wi-Fi is blocked by a hardware switch"
            : "Wi-Fi is off"
    }

    // Scrolls once the list is taller than this
    Flickable {
        id: list
        visible: Networking.wifiEnabled && networkMenu.wifiDevice !== null
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: Math.min(networks.implicitHeight, 320)
        contentHeight: networks.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: networks
            width: list.width
            spacing: 2

            Repeater {
                // Connected network first, then strongest signal first
                model: ScriptModel {
                    values: (networkMenu.wifiDevice?.networks.values ?? [])
                        .filter(n => n.name !== "")
                        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
                }

                NetworkEntry {}
            }
        }
    }

    Text {
        visible: list.visible && networks.implicitHeight === 0
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
        text: "Searching…"
    }

    component NetworkEntry: Column {
        id: entry
        required property var modelData
        readonly property bool secure: modelData.security !== WifiSecurityType.Open
        readonly property bool usesPassword: modelData.security === WifiSecurityType.WpaPsk
            || modelData.security === WifiSecurityType.Wpa2Psk
            || modelData.security === WifiSecurityType.Sae
        property bool askingPassword: false
        property string error: ""

        width: parent.width

        Connections {
            target: entry.modelData
            function onConnectionFailed(reason) {
                if (reason === ConnectionFailReason.NoSecrets && entry.usesPassword) {
                    entry.error = passwordInput.text !== "" ? "Wrong password" : ""
                    entry.askingPassword = true
                    passwordInput.text = ""
                    passwordInput.forceActiveFocus()
                } else if (reason === ConnectionFailReason.NoSecrets) {
                    entry.error = "Needs a login this menu can't provide; use nmtui"
                } else {
                    entry.error = "Couldn't connect: " + ConnectionFailReason.toString(reason)
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 32
            radius: 8
            color: hover.hovered && !entry.modelData.connected ? Theme.highlight : "transparent"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                SignalBars {
                    anchors.verticalCenter: parent.verticalCenter
                    strength: entry.modelData.signalStrength
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Theme.textOffset
                    width: Math.min(implicitWidth, entry.width - 120)
                    elide: Text.ElideRight
                    text: entry.modelData.name
                    font.pixelSize: Theme.fontSize
                    font.bold: entry.modelData.connected
                    color: entry.modelData.connected ? Theme.accent : Theme.textColor
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Theme.textOffset
                    visible: entry.modelData.stateChanging
                    text: entry.modelData.state === ConnectionState.Disconnecting ? "Disconnecting…" : "Connecting…"
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.dimTextColor
                }

                // Lock on secured networks that aren't connected
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.secure && !entry.modelData.connected
                    text: "" // lock
                    font.family: Theme.iconFont
                    font.weight: Font.Black
                    font.pixelSize: Theme.iconSize
                    color: Theme.dimTextColor
                }

                // Disconnect button on the connected network
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.modelData.connected && !entry.modelData.stateChanging
                    width: disconnectLabel.implicitWidth + 16
                    height: 22
                    radius: height / 2
                    color: disconnectHover.hovered ? Theme.highlight : Theme.surface

                    Text {
                        id: disconnectLabel
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: Theme.textOffset
                        text: "Disconnect"
                        font.pixelSize: Theme.fontSize - 2
                        color: Theme.textColor
                    }

                    HoverHandler { id: disconnectHover }
                    TapHandler { onTapped: entry.modelData.disconnect() }
                }
            }

            HoverHandler { id: hover }

            TapHandler {
                enabled: !entry.modelData.connected && !entry.modelData.stateChanging
                onTapped: {
                    entry.error = ""
                    entry.askingPassword = false
                    entry.modelData.connect()
                }
            }
        }

        // Password field, shown when the network needs one
        Rectangle {
            visible: entry.askingPassword
            x: 8
            width: parent.width - 16
            height: 30
            radius: 8
            color: Theme.surface
            border.width: passwordInput.activeFocus ? 1 : 0
            border.color: Theme.accent

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                clip: true
                font.pixelSize: Theme.fontSize
                color: Theme.textColor
                selectionColor: Theme.accent

                onAccepted: {
                    entry.error = ""
                    entry.askingPassword = false
                    entry.modelData.connectWithPsk(text)
                }
                Keys.onEscapePressed: {
                    entry.askingPassword = false
                    text = ""
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: passwordInput.text === ""
                    text: "Password"
                    font.pixelSize: Theme.fontSize
                    color: Theme.dimTextColor
                }
            }
        }

        Text {
            visible: entry.error !== ""
            x: 8
            width: parent.width - 16
            wrapMode: Text.Wrap
            topPadding: 2
            bottomPadding: 4
            text: entry.error
            font.pixelSize: Theme.fontSize - 2
            color: Theme.bad
        }
    }

    // Four bars, lit according to signal strength (0-1)
    component SignalBars: Row {
        property real strength: 0
        readonly property int lit: Math.max(1, Math.ceil(strength * 4))
        spacing: 2
        height: 12

        Repeater {
            model: 4

            Rectangle {
                required property int index
                anchors.bottom: parent.bottom
                width: 3
                height: 3 + index * 3
                radius: 1
                color: index < parent.lit ? Theme.textColor : Theme.surface
            }
        }
    }
}
