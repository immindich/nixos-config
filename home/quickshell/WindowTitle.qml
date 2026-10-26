import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

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

    // The app id (window class) names the desktop entry, which names the icon
    readonly property string appId: onScreen ? (toplevel.wayland?.appId ?? "") : ""
    readonly property var desktopEntry: {
        // The lookup isn't reactive on its own; depend on the index so it
        // runs again once the entries are scanned
        DesktopEntries.applications.values
        return appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
    }

    visible: title !== ""
    // Widest the pill may get; longer titles are cut off with "…"
    property real maxWidth: 600

    implicitWidth: row.implicitWidth + 24
    implicitHeight: Theme.bubbleHeight
    radius: height / 2
    color: Theme.background

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        IconImage {
            id: icon
            implicitSize: 16
            source: Quickshell.iconPath(desktopEntry?.icon ?? "", "application-x-executable")
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
