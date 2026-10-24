import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.menus

// The windows on a workspace, listed below its circle in WorkspaceSwitcher
// while the pointer rests on the circle or on the list itself. Clicking a
// window focuses it. One instance serves every circle: hovering another one
// moves the list there.
PopupWindow {
    id: popup

    // The circle under the pointer, if any; set by the switcher
    property Item hoveredButton: null
    // The circle the list hangs from and its workspace. These stay put while
    // the pointer is on the list, or passes over an empty circle. The anchor
    // item is kept here too because anchor.item doesn't announce changes, so
    // bindings can't depend on it.
    property Item listedButton: null
    property HyprlandWorkspace workspace: null

    // Pointer entered `button` (a WorkspaceButton)
    function hover(button) {
        if (button.ws && !button.empty) {
            listedButton = button
            workspace = button.ws
            anchor.item = button
            if (visible)
                anchor.updateAnchor()
        }
        hoveredButton = button
    }

    // Pointer left `button`
    function unhover(button) {
        if (hoveredButton === button)
            hoveredButton = null
    }

    // Hide at once, e.g. when a click switches the workspace
    function dismiss() {
        openDelay.stop()
        closeDelay.stop()
        visible = false
    }

    // Shown while the pointer is on the listed workspace's circle or on the
    // list, as long as there's something to list and no dropdown menu is
    // open (the launcher would overlap it)
    readonly property bool wanted: (hoveredButton !== null && hoveredButton === listedButton || listHover.hovered)
        && workspace !== null && workspace.toplevels.values.length > 0
        && MenuState.openMenu === null

    // Open after a short rest, like a tooltip; close after a grace period, so
    // the pointer can cross the gap between the circle and the list
    onWantedChanged: {
        if (wanted) {
            closeDelay.stop()
            if (!visible)
                openDelay.restart()
        } else {
            openDelay.stop()
            closeDelay.restart()
        }
    }
    Timer {
        id: openDelay
        interval: 500
        onTriggered: popup.visible = true
    }
    Timer {
        id: closeDelay
        interval: 300
        onTriggered: popup.visible = false
    }

    // Hang below the bar, centered on the circle, like DropdownMenu. The
    // circle is only known once hovered, so the rect is set when the anchor
    // is about to be used rather than bound (a binding made while the item
    // was still null would never pick it up).
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.onAnchoring: {
        anchor.rect.x = (anchor.item.width - implicitWidth) / 2
        anchor.rect.y = anchor.item.height + 8
    }

    // As wide as the longest title, up to a limit; longer ones are elided
    implicitWidth: Math.min(360, list.implicitWidth + 12)
    implicitHeight: list.implicitHeight + 12
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.background

        HoverHandler { id: listHover }

        ColumnLayout {
            id: list
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            Repeater {
                model: ScriptModel {
                    values: popup.workspace?.toplevels.values ?? []
                }

                // App icon and title in a pill; the focused window's title is
                // in the accent color
                Rectangle {
                    id: entry
                    required property HyprlandToplevel modelData
                    // The app id (window class) names the desktop entry,
                    // which names the icon. The Wayland handle that carries
                    // it is null until Hyprland reports the window's address.
                    readonly property string appId: modelData.wayland?.appId ?? ""
                    readonly property var desktopEntry: {
                        // The lookup isn't reactive on its own; depend on the
                        // index so it runs again once the entries are scanned,
                        // which takes a moment after the shell starts
                        DesktopEntries.applications.values
                        return appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
                    }

                    Layout.fillWidth: true
                    implicitWidth: row.implicitWidth + 16
                    implicitHeight: Theme.bubbleHeight
                    radius: height / 2
                    color: entryHover.hovered ? Theme.highlight : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

                    RowLayout {
                        id: row
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        IconImage {
                            implicitSize: 16
                            source: Quickshell.iconPath(entry.desktopEntry?.icon ?? "", "application-x-executable")
                        }

                        Text {
                            Layout.fillWidth: true
                            text: entry.modelData.title
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pixelSize: Theme.fontSize
                            color: entry.modelData.activated ? Theme.accent : Theme.textColor
                        }
                    }

                    HoverHandler { id: entryHover }

                    TapHandler {
                        onTapped: {
                            entry.modelData.wayland?.activate()
                            popup.dismiss()
                        }
                    }
                }
            }
        }
    }
}
