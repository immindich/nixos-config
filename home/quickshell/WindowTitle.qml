import QtQuick
import Quickshell.Hyprland

// Title of the focused window, in a pill matching WorkspaceSwitcher
Rectangle {
    // Hyprland keeps reporting the last active window after switching to an
    // empty workspace, so only show it while it's on the focused workspace
    // or on a special workspace that's open on top of it
    readonly property var toplevel: Hyprland.activeToplevel
    readonly property bool onScreen: toplevel !== null
        && (toplevel.workspace === Hyprland.focusedWorkspace
            || openSpecials.includes(toplevel.workspace?.name))

    // Names of the special workspaces open on any monitor, e.g. "special:magic".
    // Only the monitors' IPC data has this, and it isn't refreshed on its own.
    readonly property var openSpecials: Hyprland.monitors.values
        .map(m => m.lastIpcObject?.specialWorkspace?.name ?? "")
        .filter(name => name !== "")

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial")
                Hyprland.refreshMonitors()
        }
    }
    readonly property string title: onScreen ? toplevel.title : ""

    visible: title !== ""
    // Widest the pill may get; longer titles are cut off with "…"
    property real maxWidth: 600

    implicitWidth: label.width + 24
    implicitHeight: Theme.bubbleHeight
    radius: height / 2
    color: Theme.background

    Text {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Theme.textOffset
        width: Math.max(0, Math.min(implicitWidth, parent.maxWidth - 24))
        text: parent.title
        textFormat: Text.PlainText
        elide: Text.ElideRight
        font.pixelSize: Theme.fontSize
        color: Theme.textColor
    }
}
