import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// One half of the audio menu: heading with mute button, volume slider for the
// default device, and the list of devices (click one to make it the default).
// `sink: true` is for outputs (speakers), false for inputs (microphones).
// Needs the nodes to be tracked by a PwObjectTracker (StatusArea has one).
Column {
    id: section

    property string title
    property bool sink: true
    // May briefly be null while the default switches
    readonly property var current: sink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource

    width: parent.width - parent.leftPadding - parent.rightPadding
    spacing: 6

    Item {
        width: parent.width
        implicitHeight: Math.max(heading.implicitHeight, muteButton.height)

        MenuHeading {
            id: heading
            anchors.verticalCenter: parent.verticalCenter
            text: section.title
        }

        Rectangle {
            id: muteButton
            readonly property bool muted: section.current?.audio?.muted ?? false
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: section.current !== null
            width: 28
            height: 22
            radius: height / 2
            color: muted ? Theme.bad : muteHover.hovered ? Theme.highlight : Theme.surface

            Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

            Text {
                anchors.centerIn: parent
                text: section.sink
                    ? (muteButton.muted ? "\uf6a9" : "\uf028")  // volume-xmark : volume-high
                    : (muteButton.muted ? "\uf131" : "\uf130")  // microphone-slash : microphone
                font.family: Theme.iconFont
                font.weight: Font.Black
                font.pixelSize: Theme.iconSize
                color: muteButton.muted ? Theme.background : Theme.textColor
            }

            HoverHandler { id: muteHover }
            TapHandler { onTapped: section.current.audio.muted = !muteButton.muted }
        }
    }

    MenuSlider {
        id: volumeSlider
        visible: section.current !== null
        from: 0
        to: 1
        // value follows the device's volume via the Binding below
        live: true
        onMoved: section.current.audio.volume = value
    }

    // Follow outside changes (e.g. volume keys), but not while dragging
    Binding {
        target: volumeSlider
        property: "value"
        value: section.current?.audio?.volume ?? 0
        when: !volumeSlider.pressed
        delayed: true
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: ScriptModel {
                values: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && n.isSink === section.sink)
            }

            Rectangle {
                id: row
                required property var modelData
                readonly property bool selected: modelData === section.current
                // Short names like "Speaker" / "HDMI 1" rather than the full
                // "Raptor Lake-P/U/H cAVS Speaker"
                readonly property string label: modelData.nickname || modelData.description || modelData.name

                width: parent.width
                height: 32
                radius: 8
                color: hover.hovered && !selected ? Theme.highlight : "transparent"

                Text {
                    id: typeIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    horizontalAlignment: Text.AlignHCenter
                    text: row.modelData.name.startsWith("bluez") ? "\uf025" // headphones
                        : !section.sink ? "\uf130"                          // microphone
                        : row.label.includes("HDMI") ? "\uf26c"             // tv
                        : "\uf028"                                          // volume-high
                    font.family: Theme.iconFont
                    font.weight: Font.Black
                    font.pixelSize: Theme.iconSize
                    color: row.selected ? Theme.accent : Theme.textColor
                }

                Text {
                    anchors.left: typeIcon.right
                    anchors.leftMargin: 8
                    anchors.right: check.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Theme.textOffset
                    elide: Text.ElideRight
                    text: row.label
                    font.pixelSize: Theme.fontSize
                    font.bold: row.selected
                    color: row.selected ? Theme.accent : Theme.textColor
                }

                Text {
                    id: check
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.selected ? "\uf00c" : "" // check
                    font.family: Theme.iconFont
                    font.weight: Font.Black
                    font.pixelSize: Theme.iconSize
                    color: Theme.accent
                }

                HoverHandler { id: hover }

                TapHandler {
                    enabled: !row.selected
                    onTapped: {
                        if (section.sink)
                            Pipewire.preferredDefaultAudioSink = row.modelData
                        else
                            Pipewire.preferredDefaultAudioSource = row.modelData
                    }
                }
            }
        }
    }
}
