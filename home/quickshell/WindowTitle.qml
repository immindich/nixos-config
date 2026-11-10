import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Title of the focused window, sized like WorkspaceSwitcher
Item {
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
    property real maxWidth: Theme.px(600)

    implicitWidth: row.implicitWidth + Theme.px(24)
    implicitHeight: Theme.bubbleHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.px(8)

        AppIcon {
            id: icon
            implicitSize: Theme.px(16)
            appId: onScreen ? (toplevel.wayland?.appId ?? "") : ""
        }

        Text {
            id: label
            Layout.topMargin: Theme.textOffset * 2
            Layout.maximumWidth: Math.max(0, maxWidth - 24 - icon.implicitSize - row.spacing)
            text: title
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize
            color: Theme.textColor
        }
    }
}
