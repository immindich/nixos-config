import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.menus

// Right side of the bar, after ashell's Tempo, Privacy and Settings modules:
// privacy indicators, then volume, brightness, network, battery and the clock
Rectangle {
    id: statusArea
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + 12
    implicitHeight: Theme.bubbleHeight
    radius: height / 2
    color: Theme.background


    // Font Awesome solid glyph
    component Icon: Text {
        font.family: Theme.iconFont
        font.weight: Font.Black
        font.pixelSize: Theme.iconSize
        color: Theme.textColor
        anchors.verticalCenter: parent.verticalCenter
    }

    component Label: Text {
        font.pixelSize: Theme.fontSize
        color: Theme.textColor
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Theme.textOffset
    }

    // Icon followed by a value, e.g. "🔈 23%", in a pill. Clicking anywhere on
    // the pill toggles `menu` if set, otherwise emits `clicked()`. The pill is
    // highlighted while the menu is open or `active` is true.
    component Indicator: Rectangle {
        id: indicator
        property alias icon: icon.text
        property alias iconFont: icon.font.family // Theme.brandIconFont for brand glyphs
        property alias text: label.text
        // Optional item shown in place of (or before) the icon, e.g. the
        // network indicator's signal bars. Shown while `extraVisible`; it's
        // set here rather than on the item, since an item under a hidden
        // parent reads as hidden itself, which would keep it hidden for good.
        property Component extra: null
        property bool extraVisible: false
        property color contentColor: Theme.textColor
        property DropdownMenu menu: null
        property bool active: false
        signal clicked()

        implicitWidth: content.implicitWidth + 12
        implicitHeight: Theme.workspaceSize
        radius: height / 2
        color: menu?.visible || active ? Theme.highlight : "transparent"
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 4

            Loader {
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: indicator.extra
                visible: indicator.extraVisible
            }
            Icon { id: icon; color: indicator.contentColor; visible: text !== "" }
            Label { id: label; color: indicator.contentColor; visible: text !== "" }
        }

        TapHandler {
            onTapped: {
                if (indicator.menu)
                    indicator.menu.toggle()
                else
                    indicator.clicked()
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Keep the screen awake while IdleInhibit is on (toggled from the power
    // menu). Attached to this bar's window, which the compositor respects.
    IdleInhibitor {
        window: statusArea.QsWindow.window
        enabled: IdleInhibit.enabled
    }

    // Pipewire nodes must be tracked for volume and properties to be valid
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    Row {
        id: row
        anchors.centerIn: parent
        // Indicators are padded pills; this plus their padding spaces items
        // 14px apart
        spacing: 2

        // Media player: play icon while playing, dimmed pause icon while
        // paused; hidden when no player is running
        Indicator {
            id: media
            menu: MediaMenu { anchor.item: media }

            readonly property var player: Media.player
            readonly property bool playing: player?.isPlaying ?? false
            visible: player !== null
            icon: playing ? "\uf04b" : "\uf04c" // play : pause
            contentColor: playing ? Theme.textColor : Theme.dimTextColor
            text: ""
        }

        // Clipboard history
        Indicator {
            id: clipboard
            menu: ClipboardMenu { anchor.item: clipboard }

            icon: "\uf328" // clipboard
            text: ""
        }

        // Notification count; bell-slash while do-not-disturb is on
        Indicator {
            id: notifications
            menu: NotificationMenu { anchor.item: notifications }

            readonly property int count: Notifications.history.length
            icon: Notifications.dnd ? "\uf1f6" : "\uf0f3" // bell-slash : bell
            contentColor: Notifications.dnd ? Theme.dimTextColor : Theme.textColor
            text: count > 0 ? count : ""
        }

        // Weather: conditions icon and temperature; hidden until the first
        // forecast arrives
        Indicator {
            id: weatherIndicator
            menu: WeatherMenu { anchor.item: weatherIndicator }

            visible: Weather.available
            icon: Weather.icon
            text: Weather.temperature + "°"
        }

        Privacy { anchors.verticalCenter: parent.verticalCenter }

        Indicator {
            id: volume
            menu: AudioMenu { anchor.item: volume }

            readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
            readonly property bool muted: !audio || audio.muted
            visible: audio !== null
            // Muted: speaker with a cross. Otherwise the bare speaker with
            // sound-wave arcs lit by volume.
            icon: muted ? "\uf6a9" : "" // volume-xmark
            text: ""
            extraVisible: !muted
            extra: Row {
                spacing: 1
                Icon { text: "\uf026" } // volume-off (bare speaker)
                VolumeArcs {
                    anchors.verticalCenter: parent.verticalCenter
                    level: volume.audio?.volume ?? 0
                }
            }

            // Middle click mutes and unmutes
            TapHandler {
                acceptedButtons: Qt.MiddleButton
                onTapped: if (volume.audio) volume.audio.muted = !volume.audio.muted
            }

            // Scroll to change the volume in 5% steps, unmuting first, like
            // the volume keys
            WheelSteps {
                onStepped: direction => {
                    if (!volume.audio)
                        return
                    volume.audio.muted = false
                    volume.audio.volume = Math.min(1, Math.max(0, Math.round(volume.audio.volume * 100 + 5 * direction) / 100))
                }
            }
        }

        Indicator {
            id: brightness
            menu: BrightnessMenu {
                anchor.item: brightness
                current: Brightness.current
                max: Brightness.max
            }

            visible: Brightness.max > 0
            icon: "\uf185" // sun
            text: ""

            // Scroll to change the brightness in 5% steps, like the brightness keys
            WheelSteps {
                onStepped: direction => Quickshell.execDetached(["brightnessctl", "-e4", "-n2", "set", direction > 0 ? "5%+" : "5%-"])
            }
        }

        Indicator {
            id: network
            menu: NetworkMenu { anchor.item: network }

            readonly property var devices: Networking.devices.values
            readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
            readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
            readonly property bool wifi: wifiDevice?.connected ?? false
            readonly property bool connecting: wifiDevice?.state === ConnectionState.Connecting
            // The connected network, for its signal strength
            readonly property var wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

            // Wired: plug icon. Wi-Fi: signal bars, cycling while connecting.
            // Otherwise a dimmed Wi-Fi icon.
            icon: wired ? "\uf6ff" : wifi || connecting ? "" : "\uf1eb" // network-wired : wifi
            contentColor: wired ? Theme.textColor : Theme.dimTextColor
            text: ""
            extraVisible: !wired && (wifi || connecting)
            extra: SignalBars {
                strength: network.wifiNetwork?.signalStrength ?? 0
                connecting: network.connecting && !network.wifi
            }
        }

        Indicator {
            id: bluetooth
            menu: BluetoothMenu { anchor.item: bluetooth }

            readonly property var adapter: Bluetooth.defaultAdapter
            visible: adapter !== null
            icon: "\uf294" // bluetooth-b
            iconFont: Theme.brandIconFont
            contentColor: adapter?.enabled ? Theme.textColor : Theme.dimTextColor
            text: ""
        }

        Indicator {
            id: power
            menu: PowerMenu { anchor.item: power }

            readonly property var battery: UPower.displayDevice
            readonly property int percent: Math.round(battery.percentage * 100)
            readonly property bool charging: battery.state === UPowerDeviceState.Charging
                || battery.state === UPowerDeviceState.FullyCharged
            visible: battery.isLaptopBattery
            contentColor: charging ? Theme.good : percent <= 15 ? Theme.bad : Theme.textColor
            icon: charging ? "\uf0e7"   // bolt
                : percent > 87 ? "\uf240" // battery-full
                : percent > 62 ? "\uf241" // battery-three-quarters
                : percent > 37 ? "\uf242" // battery-half
                : percent > 12 ? "\uf243" // battery-quarter
                : "\uf244"                // battery-empty
            text: percent + "%"
            // Mug before the battery while the screen is kept awake
            extraVisible: IdleInhibit.enabled
            extra: Icon {
                text: "\uf7b6" // mug-hot
                color: power.contentColor
            }
        }

        // Clock; opens the calendar
        Indicator {
            id: clockIndicator
            menu: CalendarMenu {
                anchor.item: clockIndicator
                today: clock.date
            }

            icon: ""
            text: Qt.formatDateTime(clock.date, "hh:mm")
        }
    }
}
