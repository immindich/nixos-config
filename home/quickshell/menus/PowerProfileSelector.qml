import QtQuick
import Quickshell.Services.UPower
import qs

// Buttons for power-profiles-daemon's profiles, with the current one
// highlighted, plus a note when the daemon reports degraded performance.
// Sized to fill a DropdownMenu's width.
Column {
    width: parent.width - parent.leftPadding - parent.rightPadding
    spacing: Theme.px(6)

    Row {
        id: buttons
        width: parent.width
        spacing: Theme.px(4)

        Repeater {
            model: [
                { profile: PowerProfile.PowerSaver, icon: "\uf06c", label: "Saver" },        // leaf
                { profile: PowerProfile.Balanced, icon: "\uf24e", label: "Balanced" },       // scale-balanced
                { profile: PowerProfile.Performance, icon: "\uf625", label: "Performance" }, // gauge-high
            ]

            Rectangle {
                id: button
                required property var modelData
                readonly property bool selected: PowerProfiles.profile === modelData.profile
                readonly property bool available: modelData.profile !== PowerProfile.Performance
                    || PowerProfiles.hasPerformanceProfile

                width: (buttons.width - buttons.spacing * 2) / 3
                height: Theme.px(48)
                radius: Theme.px(8)
                color: selected ? Theme.controlFill : hover.hovered && available ? Theme.highlight : Theme.surface
                opacity: available ? 1 : 0.5

                Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.px(2)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: button.modelData.icon
                        font.family: Theme.iconFont
                        font.weight: Font.Black
                        font.pixelSize: Theme.iconSize
                        color: button.selected ? Theme.controlText : Theme.textColor
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: button.modelData.label
                        font.pixelSize: Theme.fontSize - Theme.px(2)
                        color: button.selected ? Theme.controlText : Theme.textColor
                    }
                }

                HoverHandler { id: hover }

                TapHandler {
                    enabled: button.available && !button.selected
                    onTapped: PowerProfiles.profile = button.modelData.profile
                }
            }
        }
    }

    Text {
        visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
        width: parent.width
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSize - Theme.px(2)
        color: Theme.dimTextColor
        text: "Performance limited: "
            + (PowerProfiles.degradationReason === PerformanceDegradationReason.LapDetected ? "lap detected"
            : PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature ? "high temperature"
            : "unknown reason")
    }
}
