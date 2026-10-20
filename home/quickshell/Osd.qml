import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// On-screen display for volume and brightness changes: a bubble at the
// bottom center of the focused screen that fades out shortly after the last
// change. Stays quiet while a menu is open (its slider already shows the
// level) and right after loading. Clicks pass through it.
PanelWindow {
    id: osd

    // "volume" or "brightness"
    property string kind: "volume"
    property bool shown: false
    // Ignore the values settling right after startup or a reload
    property bool armed: false

    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property real level: kind === "volume" ? (audio?.volume ?? 0) : Brightness.percent / 100
    readonly property bool muted: kind === "volume" && (audio?.muted ?? false)

    function show(newKind) {
        if (!armed || MenuState.openMenu !== null)
            return
        kind = newKind
        shown = true
        hideTimer.restart()
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.bottom: true
    margins.bottom: 80
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    // Empty input region: clicks go to whatever is underneath
    mask: Region {}

    visible: bubble.opacity > 0
    implicitWidth: 260
    implicitHeight: Theme.bubbleHeight + 12
    color: "transparent"

    Timer { running: true; interval: 1000; onTriggered: osd.armed = true }
    Timer { id: hideTimer; interval: 1500; onTriggered: osd.shown = false }

    Connections {
        target: osd.audio
        function onVolumeChanged() { osd.show("volume") }
        function onMutedChanged() { osd.show("volume") }
    }
    Connections {
        target: Brightness
        function onCurrentChanged() { osd.show("brightness") }
    }

    Rectangle {
        id: bubble
        anchors.fill: parent
        radius: height / 2
        color: Theme.background
        opacity: osd.shown ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Theme.animationDuration } }

        Text {
            id: icon
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            horizontalAlignment: Text.AlignHCenter
            readonly property int percent: Math.round(osd.level * 100)
            text: osd.kind === "brightness" ? "" // sun
                : osd.muted ? ""                 // volume-xmark
                : percent === 0 ? ""             // volume-off
                : percent < 50 ? ""              // volume-low
                : ""                             // volume-high
            font.family: Theme.iconFont
            font.weight: Font.Black
            font.pixelSize: Theme.iconSize + 2
            color: osd.muted ? Theme.dimTextColor : Theme.textColor
        }

        // Level bar, styled like MenuSlider's track
        Rectangle {
            id: track
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.right: value.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: height / 2
            color: Theme.surface

            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, osd.level))
                height: parent.height
                radius: height / 2
                color: osd.muted ? Theme.dimTextColor : Theme.accent

                Behavior on width { NumberAnimation { duration: 80 } }
            }
        }

        Text {
            id: value
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Theme.textOffset
            width: 36
            horizontalAlignment: Text.AlignRight
            text: osd.muted ? "Muted" : Math.round(osd.level * 100) + "%"
            font.pixelSize: Theme.fontSize
            color: osd.muted ? Theme.dimTextColor : Theme.textColor
        }
    }
}
