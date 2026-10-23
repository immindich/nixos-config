import QtQuick
import Quickshell.Services.Pipewire

// Privacy indicators: shown only while something records the mic, camera or
// screen. Reads Pipewire node properties, which StatusArea's PwObjectTracker
// keeps valid.
Row {
    id: privacy
    spacing: 8
    leftPadding: 6
    rightPadding: 6
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

    // Font Awesome solid glyph
    component Icon: Text {
        font.family: Theme.iconFont
        font.weight: Font.Black
        font.pixelSize: Theme.iconSize
        color: Theme.bad
        anchors.verticalCenter: parent.verticalCenter
    }

    Icon { text: "\uf130"; visible: privacy.micInUse }    // microphone
    Icon { text: "\uf03d"; visible: privacy.cameraInUse } // video
    Icon { text: "\uf192"; visible: privacy.screenInUse } // circle-dot (recording)
}
