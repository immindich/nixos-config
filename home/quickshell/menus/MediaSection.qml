import QtQuick
import QtQuick.Effects
import qs

// Now playing: album art, title, artist and album, a seek bar and
// previous/play-pause/next buttons for the current media player (Media.player).
// A section of the control center; set `shown` while the menu is open, which
// is when it polls the playback position.
Column {
    id: mediaSection

    width: parent.width - parent.leftPadding - parent.rightPadding
    spacing: Theme.px(8)

    // True while the menu holding this section is open
    property bool shown: false
    readonly property var player: Media.player
    readonly property bool hasProgress: player !== null && player.lengthSupported
        && player.positionSupported && player.length > 0

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

        width: primary ? Theme.px(36) : Theme.px(30)
        height: width
        radius: width / 2
        // The primary button fills like the control center's toggles
        color: primary
            ? (hover.hovered ? (Theme.fillLook === "tint" ? Theme.tint(Theme.accent, 0.42) : Qt.lighter(Theme.accent, 1.15)) : Theme.controlFill)
            : hover.hovered ? Theme.highlight : Theme.surface
        opacity: enabled ? 1 : 0.4

        Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

        Text {
            id: glyph
            anchors.centerIn: parent
            font.family: Theme.iconFont
            font.weight: Font.Black
            font.pixelSize: Theme.iconSize + (button.primary ? 2 : 0)
            color: button.primary ? Theme.controlText : Theme.textColor
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: button.clicked() }
    }

    // Players don't report playback position on their own; ask once a second
    // while the menu is open and something is playing
    Timer {
        running: mediaSection.shown && mediaSection.visible && (mediaSection.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: mediaSection.player.positionChanged()
    }

    MenuHeading { text: mediaSection.player?.identity ?? "Media" }

    // Album art beside the track details
    Row {
        width: parent.width
        spacing: Theme.px(12)

        Item {
            id: art
            width: Theme.px(64)
            height: Theme.px(64)

            // Placeholder until the art loads, or when there is none
            Rectangle {
                anchors.fill: parent
                radius: Theme.px(8)
                color: Theme.surface
                visible: !cover.visible

                Text {
                    anchors.centerIn: parent
                    text: "\uf001" // music
                    font.family: Theme.iconFont
                    font.weight: Font.Black
                    font.pixelSize: Theme.px(20)
                    color: Theme.dimTextColor
                }
            }

            Image {
                id: cover
                anchors.fill: parent
                source: mediaSection.player?.trackArtUrl ?? ""
                visible: source != "" && status === Image.Ready
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(Theme.px(128), Theme.px(128))
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
                Rectangle { anchors.fill: parent; radius: Theme.px(8) }
            }
        }

        Column {
            width: parent.width - art.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.px(2)

            Text {
                width: parent.width
                text: mediaSection.player?.trackTitle || "Nothing playing"
                textFormat: Text.PlainText
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
                text: mediaSection.player?.trackArtist ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSize - Theme.px(1)
                color: Theme.textColor
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: mediaSection.player?.trackAlbum ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSize - Theme.px(2)
                color: Theme.dimTextColor
            }
        }
    }

    // Seek bar with elapsed and total time; drag to seek if the player allows
    Column {
        visible: mediaSection.hasProgress
        width: parent.width
        spacing: Theme.px(2)

        MenuSlider {
            id: progress
            width: parent.width
            from: 0
            to: mediaSection.player?.length ?? 1
            enabled: mediaSection.player?.canSeek ?? false
            // Seek once the handle is released
            onPressedChanged: {
                if (!pressed && mediaSection.player)
                    mediaSection.player.position = value
            }
        }

        // Follow the player's position, but not while dragging
        Binding {
            target: progress
            property: "value"
            value: mediaSection.player?.position ?? 0
            when: !progress.pressed
        }

        Item {
            width: parent.width
            implicitHeight: elapsed.implicitHeight

            Text {
                id: elapsed
                anchors.left: parent.left
                text: mediaSection.formatTime(progress.value)
                font.pixelSize: Theme.fontSize - Theme.px(2)
                color: Theme.dimTextColor
            }

            Text {
                anchors.right: parent.right
                text: mediaSection.formatTime(mediaSection.player?.length ?? 0)
                font.pixelSize: Theme.fontSize - Theme.px(2)
                color: Theme.dimTextColor
            }
        }
    }

    // Controls, centered
    Item {
        width: parent.width
        implicitHeight: controls.implicitHeight

        Row {
            id: controls
            anchors.centerIn: parent
            spacing: Theme.px(12)

            ControlButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "\uf048" // backward-step
                enabled: mediaSection.player?.canGoPrevious ?? false
                onClicked: mediaSection.player.previous()
            }

            ControlButton {
                primary: true
                icon: mediaSection.player?.isPlaying ? "\uf04c" : "\uf04b" // pause : play
                enabled: mediaSection.player?.canTogglePlaying ?? false
                onClicked: mediaSection.player.togglePlaying()
            }

            ControlButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "\uf051" // forward-step
                enabled: mediaSection.player?.canGoNext ?? false
                onClicked: mediaSection.player.next()
            }
        }
    }
}
