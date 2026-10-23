import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland

// Right side of the bar, after ashell's Tempo, Privacy and Settings modules:
// clock, privacy indicators, then volume, brightness, network and battery
Rectangle {
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

        // Keep the screen awake: click to toggle. Highlighted and full color
        // while on, dimmed while off.
        Indicator {
            id: idleInhibit
            active: IdleInhibit.enabled
            icon: "\uf7b6" // mug-hot
            contentColor: IdleInhibit.enabled ? Theme.textColor : Theme.dimTextColor
            text: ""
            onClicked: IdleInhibit.enabled = !IdleInhibit.enabled

            // Attached to this bar's window, which the compositor respects
            IdleInhibitor {
                window: idleInhibit.QsWindow.window
                enabled: IdleInhibit.enabled
            }
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
            icon: Notifications.dnd ? "" : "" // bell-slash : bell
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

        // Clock; opens the calendar
        Indicator {
            id: clockIndicator
            menu: CalendarMenu {
                anchor.item: clockIndicator
                today: clock.date
            }

            icon: ""
            text: Qt.formatDateTime(clock.date, "ddd d MMM hh:mm")
        }

        // Privacy: shown only while something records the mic, camera or screen
        Row {
            id: privacy
            spacing: 8
            leftPadding: 6
            rightPadding: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: micInUse || cameraInUse || screenInUse

            readonly property bool micInUse: Pipewire.nodes.values.some(n => n.properties?.["media.class"] === "Stream/Input/Audio")
            // Video streams are split into screen sharing (fed by the Hyprland
            // portal) and everything else (cameras). The portal's node is named
            // after its binary, ".xdg-desktop-portal-hyprland-wrapped" on NixOS.
            readonly property var videoSources: Pipewire.links.values
                .filter(l => l.target?.properties?.["media.class"] === "Stream/Input/Video")
                .map(l => l.source?.name ?? "")
            readonly property bool screenInUse: videoSources.some(n => n.includes("xdg-desktop-portal-hyprland"))
            readonly property bool cameraInUse: videoSources.some(n => !n.includes("xdg-desktop-portal-hyprland"))

            Icon { text: ""; color: Theme.bad; visible: privacy.micInUse }    // microphone
            Icon { text: ""; color: Theme.bad; visible: privacy.cameraInUse } // video
            Icon { text: ""; color: Theme.bad; visible: privacy.screenInUse } // circle-dot (recording)
        }

        Indicator {
            id: volume
            menu: AudioMenu { anchor.item: volume }

            readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
            readonly property int percent: audio ? Math.round(audio.volume * 100) : 0
            visible: audio !== null
            icon: !audio || audio.muted ? ""   // volume-xmark
                : percent === 0 ? ""           // volume-off
                : percent < 50 ? ""            // volume-low
                : ""                           // volume-high
            text: audio && !audio.muted ? percent + "%" : ""

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
            icon: "" // sun
            text: Brightness.percent + "%"

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
            icon: wired ? "" : wifi || connecting ? "" : "" // network-wired : wifi
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
            icon: "" // bluetooth-b
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
            icon: charging ? ""   // bolt
                : percent > 87 ? "" // battery-full
                : percent > 62 ? "" // battery-three-quarters
                : percent > 37 ? "" // battery-half
                : percent > 12 ? "" // battery-quarter
                : ""                // battery-empty
            text: percent + "%"
        }
    }
}
