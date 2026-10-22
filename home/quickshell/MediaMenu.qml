import QtQuick
import QtQuick.Effects

// Now playing: album art, title, artist and album, a seek bar and
// previous/play-pause/next buttons for the current media player (Media.player).
// Opened from the media indicator; set `anchor.item` to it.
DropdownMenu {
    id: mediaMenu

    readonly property var player: Media.player
    readonly property bool hasProgress: player !== null && player.lengthSupported
        && player.positionSupported && player.length > 0

    implicitWidth: 320

    // "1:05" or "1:02:33"
    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds))
        const m = Math.floor(s / 60) % 60
        const h = Math.floor(s / 3600)
        const pad = n => (n < 10 ? "0" : "") + n
        return h > 0 ? h + ":" + pad(m) + ":" + pad(s % 60) : m + ":" + pad(s % 60)
    }

    // Round button with a Font Awesome glyph; dimmed and inert while disabled
    component ControlButton: Rectangle {
        id: button
        property alias icon: glyph.text
        property bool primary: false
        signal clicked()

        width: primary ? 36 : 30
        height: width
        radius: width / 2
        color: primary ? (hover.hovered ? Qt.lighter(Theme.accent, 1.15) : Theme.accent)
            : hover.hovered ? Theme.highlight : Theme.surface
        opacity: enabled ? 1 : 0.4

        Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

        Text {
            id: glyph
            anchors.centerIn: parent
            font.family: Theme.iconFont
            font.weight: Font.Black
            font.pixelSize: Theme.iconSize + (button.primary ? 2 : 0)
            color: button.primary ? Theme.background : Theme.textColor
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: button.clicked() }
    }

    // Players don't report playback position on their own; ask once a second
    // while the menu is open and something is playing
    Timer {
        running: mediaMenu.visible && (mediaMenu.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: mediaMenu.player.positionChanged()
    }

    MenuHeading { text: mediaMenu.player?.identity ?? "Media" }

    // Album art beside the track details
    Row {
        width: parent.width - parent.leftPadding - parent.rightPadding
        spacing: 12

        Item {
            id: art
            width: 64
            height: 64

            // Placeholder until the art loads, or when there is none
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.surface
                visible: !cover.visible

                Text {
                    anchors.centerIn: parent
                    text: "\uf001" // music
                    font.family: Theme.iconFont
                    font.weight: Font.Black
                    font.pixelSize: 20
                    color: Theme.dimTextColor
                }
            }

            Image {
                id: cover
                anchors.fill: parent
                source: mediaMenu.player?.trackArtUrl ?? ""
                visible: source != "" && status === Image.Ready
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(128, 128)
                // Rounded corners
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: artMask
                }
            }

            Item {
                id: artMask
                anchors.fill: parent
                layer.enabled: true
                visible: false
                Rectangle { anchors.fill: parent; radius: 8 }
            }
        }

        Column {
            width: parent.width - art.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: mediaMenu.player?.trackTitle || "Nothing playing"
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSize
                font.bold: true
                color: Theme.textColor
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: mediaMenu.player?.trackArtist ?? ""
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSize - 1
                color: Theme.textColor
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: mediaMenu.player?.trackAlbum ?? ""
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSize - 2
                color: Theme.dimTextColor
            }
        }
    }

    // Seek bar with elapsed and total time; drag to seek if the player allows
    Column {
        visible: mediaMenu.hasProgress
        width: parent.width - parent.leftPadding - parent.rightPadding
        spacing: 2

        MenuSlider {
            id: progress
            width: parent.width
            from: 0
            to: mediaMenu.player?.length ?? 1
            enabled: mediaMenu.player?.canSeek ?? false
            // Seek once the handle is released
            onPressedChanged: {
                if (!pressed && mediaMenu.player)
                    mediaMenu.player.position = value
            }
        }

        // Follow the player's position, but not while dragging
        Binding {
            target: progress
            property: "value"
            value: mediaMenu.player?.position ?? 0
            when: !progress.pressed
        }

        Item {
            width: parent.width
            implicitHeight: elapsed.implicitHeight

            Text {
                id: elapsed
                anchors.left: parent.left
                text: mediaMenu.formatTime(progress.value)
                font.pixelSize: Theme.fontSize - 2
                color: Theme.dimTextColor
            }

            Text {
                anchors.right: parent.right
                text: mediaMenu.formatTime(mediaMenu.player?.length ?? 0)
                font.pixelSize: Theme.fontSize - 2
                color: Theme.dimTextColor
            }
        }
    }

    // Controls, centered
    Item {
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: controls.implicitHeight

        Row {
            id: controls
            anchors.centerIn: parent
            spacing: 12

            ControlButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "\uf048" // backward-step
                enabled: mediaMenu.player?.canGoPrevious ?? false
                onClicked: mediaMenu.player.previous()
            }

            ControlButton {
                primary: true
                icon: mediaMenu.player?.isPlaying ? "\uf04c" : "\uf04b" // pause : play
                enabled: mediaMenu.player?.canTogglePlaying ?? false
                onClicked: mediaMenu.player.togglePlaying()
            }

            ControlButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "\uf051" // forward-step
                enabled: mediaMenu.player?.canGoNext ?? false
                onClicked: mediaMenu.player.next()
            }
        }
    }
}
