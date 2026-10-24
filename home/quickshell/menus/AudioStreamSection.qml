import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs

// Applications tab of the audio menu: every program currently playing
// audio, each with its own mute button and volume slider. Needs the nodes
// to be tracked by a PwObjectTracker (StatusArea has one).
Column {
    id: section

    width: parent.width - parent.leftPadding - parent.rightPadding
    spacing: 6

    Text {
        visible: streams.values.length === 0
        text: "Nothing playing"
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
    }

    Repeater {
        model: ScriptModel {
            id: streams
            // Programs playing audio. (Not isSink: a playback stream counts
            // as a sink, since it takes audio in from its program.)
            values: Pipewire.nodes.values.filter(n => n.audio && n.properties?.["media.class"] === "Stream/Output/Audio")
        }

        Column {
            id: stream
            required property var modelData
            readonly property var props: modelData.properties ?? {}
            readonly property string label: props["application.name"] || modelData.nickname
                || modelData.description || modelData.name
            // What's playing, e.g. a video's title; shown after the name
            readonly property string media: props["media.name"] ?? ""
            readonly property string iconSource: Quickshell.iconPath(props["application.icon-name"] ?? "", true)

            // The label below is StyledText, so markup in the names (a web
            // page's title, say) must be escaped or it would be rendered
            function escapeMarkup(s) {
                return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            }

            width: parent.width
            spacing: 4

            Item {
                width: parent.width
                implicitHeight: Math.max(name.implicitHeight, muteButton.height)

                IconImage {
                    id: appIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 18
                    source: stream.iconSource
                    visible: source != ""
                }

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !appIcon.visible
                    width: 18
                    horizontalAlignment: Text.AlignHCenter
                    text: "\uf028" // volume-high
                    font.family: Theme.iconFont
                    font.weight: Font.Black
                    font.pixelSize: Theme.iconSize
                    color: Theme.textColor
                }

                Text {
                    id: name
                    anchors.left: parent.left
                    anchors.leftMargin: 26
                    anchors.right: muteButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Theme.textOffset
                    elide: Text.ElideRight
                    textFormat: Text.StyledText
                    text: stream.media !== "" && stream.media !== stream.label
                        ? stream.escapeMarkup(stream.label) + " <font color=\"" + Theme.dimTextColor + "\">" + stream.escapeMarkup(stream.media) + "</font>"
                        : stream.escapeMarkup(stream.label)
                    font.pixelSize: Theme.fontSize
                    color: Theme.textColor
                }

                Rectangle {
                    id: muteButton
                    readonly property bool muted: stream.modelData.audio.muted
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 22
                    radius: height / 2
                    color: muted ? Theme.bad : muteHover.hovered ? Theme.highlight : Theme.surface

                    Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

                    Text {
                        anchors.centerIn: parent
                        text: muteButton.muted ? "\uf6a9" : "\uf028" // volume-xmark : volume-high
                        font.family: Theme.iconFont
                        font.weight: Font.Black
                        font.pixelSize: Theme.iconSize
                        color: muteButton.muted ? Theme.background : Theme.textColor
                    }

                    HoverHandler { id: muteHover }
                    TapHandler { onTapped: stream.modelData.audio.muted = !muteButton.muted }
                }
            }

            MenuSlider {
                id: volumeSlider
                from: 0
                to: 1
                // value follows the stream's volume via the Binding below
                live: true
                onMoved: stream.modelData.audio.volume = value
            }

            // Follow outside changes (e.g. the app's own volume control), but
            // not while dragging
            Binding {
                target: volumeSlider
                property: "value"
                value: stream.modelData.audio.volume
                when: !volumeSlider.pressed
                delayed: true
            }
        }
    }
}
