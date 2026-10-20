import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

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
    // the pill toggles `menu`, if set, and the pill is highlighted while the
    // menu is open.
    component Indicator: Rectangle {
        id: indicator
        property alias icon: icon.text
        property alias text: label.text
        property color contentColor: Theme.textColor
        property DropdownMenu menu: null

        implicitWidth: content.implicitWidth + 12
        implicitHeight: Theme.workspaceSize
        radius: height / 2
        color: menu?.visible ? Theme.highlight : "transparent"
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 4

            Icon { id: icon; color: indicator.contentColor }
            Label { id: label; color: indicator.contentColor; visible: text !== "" }
        }

        TapHandler {
            enabled: indicator.menu !== null
            onTapped: indicator.menu.toggle()
        }
    }

    // Placeholder menu contents; replace with real controls
    component MenuPlaceholder: Rectangle {
        property alias text: placeholderLabel.text
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: 32
        radius: 8
        color: Theme.surface

        Text {
            id: placeholderLabel
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSize
            color: Theme.dimTextColor
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

    FileView { id: brightnessFile; path: "/sys/class/backlight/intel_backlight/brightness" }
    FileView { id: maxBrightnessFile; path: "/sys/class/backlight/intel_backlight/max_brightness" }

    // sysfs doesn't send file change notifications, but the kernel announces
    // backlight changes as udev events (this is how ashell does it). Each line
    // udevadm prints means something may have changed, so re-read the file.
    Process {
        id: backlightMonitor
        running: true
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        stdout: SplitParser {
            onRead: brightnessFile.reload()
        }
        // Restart it if it exits or fails to start, after a cooldown so a
        // broken command doesn't run in a tight loop
        onRunningChanged: if (!running) backlightRestart.start()
    }
    Timer {
        id: backlightRestart
        interval: 5000
        onTriggered: {
            brightnessFile.reload() // catch changes missed while it was down
            backlightMonitor.running = true
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        // Indicators are padded pills; this plus their padding spaces items
        // 14px apart
        spacing: 2

        Label {
            text: Qt.formatDateTime(clock.date, "ddd d MMM hh:mm")
            leftPadding: 6
            rightPadding: 6
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
            // portal) and everything else (cameras)
            readonly property var videoSources: Pipewire.links.values
                .filter(l => l.target?.properties?.["media.class"] === "Stream/Input/Video")
                .map(l => l.source?.name ?? "")
            readonly property bool screenInUse: videoSources.some(n => n.startsWith("xdph"))
            readonly property bool cameraInUse: videoSources.some(n => !n.startsWith("xdph"))

            Icon { text: ""; color: Theme.bad; visible: privacy.micInUse }    // microphone
            Icon { text: ""; color: Theme.bad; visible: privacy.cameraInUse } // video
            Icon { text: ""; color: Theme.bad; visible: privacy.screenInUse } // display
        }

        Indicator {
            id: volume
            menu: DropdownMenu {
                anchor.item: volume
                MenuHeading { text: "Sound" }
                MenuPlaceholder { text: "Placeholder 1" }
                MenuPlaceholder { text: "Placeholder 2" }
            }

            readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
            readonly property int percent: audio ? Math.round(audio.volume * 100) : 0
            visible: audio !== null
            icon: !audio || audio.muted ? ""   // volume-xmark
                : percent === 0 ? ""           // volume-off
                : percent < 50 ? ""            // volume-low
                : ""                           // volume-high
            text: audio && !audio.muted ? percent + "%" : ""
        }

        Indicator {
            id: brightness
            menu: DropdownMenu {
                anchor.item: brightness
                MenuHeading { text: "Brightness" }
                MenuSlider {
                    id: brightnessSlider
                    from: 0
                    to: brightness.max
                    // value follows the real brightness via the Binding below
                    live: true
                    // start() is a no-op while the timer runs, so a drag sends
                    // at most one update per interval
                    onMoved: backlightApply.start()
                }
            }
            readonly property int max: parseInt(maxBrightnessFile.text())
            readonly property int current: parseInt(brightnessFile.text())
            readonly property int percent: Math.floor(current / max * 100)
            visible: max > 0
            icon: "" // sun
            text: Math.floor(current / max * 100) + "%"

            Process {
                id: backlightSetter
                running: false
                command: ["brightnessctl", "set", Math.round(brightnessSlider.value)]
            }

            // Sends the slider's latest value shortly after it changes. If the
            // previous brightnessctl is still running (so starting it again
            // would do nothing), waits and tries again instead of dropping it.
            Timer {
                id: backlightApply
                interval: 50
                onTriggered: {
                    if (backlightSetter.running)
                        restart()
                    else
                        backlightSetter.running = true
                }
            }

            // Follow outside changes (e.g. brightness keys), but not while
            // dragging, when the real brightness lags behind the handle
            Binding {
                target: brightnessSlider
                property: "value"
                // Reapply once max is read too; before that `to` is 0 and the
                // slider clamps the value to 0. Delayed so `to` has updated
                // by the time the value is applied.
                value: brightness.max > 0 ? brightness.current : 0
                when: !brightnessSlider.pressed
                delayed: true
            }
        }

        Indicator {
            id: network
            menu: DropdownMenu {
                anchor.item: network
                MenuHeading { text: "Network" }
                MenuPlaceholder { text: "Placeholder 1" }
                MenuPlaceholder { text: "Placeholder 2" }
            }

            readonly property var devices: Networking.devices.values
            readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
            readonly property bool wifi: devices.some(d => d.type === DeviceType.Wifi && d.connected)
            icon: wired ? "" : "" // network-wired : wifi
            contentColor: wired || wifi ? Theme.textColor : Theme.dimTextColor
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
