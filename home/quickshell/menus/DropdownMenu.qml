import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// Popup that opens below `anchor.item`, styled like the bar's bubbles.
// Children are stacked vertically. Menus that take keyboard input use
// KeyboardMenu instead. Clicking outside the menu or right-clicking
// inside it closes it, and opening a menu closes any other open one.
PopupWindow {
    id: menu

    default property alias content: column.data

    // Hang below the bar, centered on the anchor item; slides back on screen
    // if it would go past the edge
    anchor.rect.x: anchor.item ? (anchor.item.width - width) / 2 : 0
    anchor.rect.y: anchor.item ? anchor.item.height + 8 : 0
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right

    implicitWidth: 280
    implicitHeight: column.implicitHeight // includes the column's padding
    color: "transparent"

    // Tallest the content can be before the menu runs off the bottom of the
    // screen, for menus that scroll a long list. The menu hangs just below
    // the bar and keeps the bar's margin from the bottom edge.
    readonly property int maxContentHeight: (anchor.item?.QsWindow.window?.screen?.height ?? 0)
        - Theme.barHeight - Theme.barMargin - 2 * column.padding

    function toggle() {
        menu.visible = !menu.visible
    }

    onVisibleChanged: {
        if (visible) {
            if (MenuState.openMenu && MenuState.openMenu !== menu)
                MenuState.openMenu.visible = false
            MenuState.openMenu = menu
        } else if (MenuState.openMenu === menu) {
            MenuState.openMenu = null
        }
    }

    // Hyprland rejects a grab on a window that isn't mapped yet, so start it
    // once the popup is actually on screen. Setting it false first re-requests
    // a grab the compositor has already cleared.
    function updateGrab() {
        grab.active = false
        grab.active = backingWindowVisible
    }
    onBackingWindowVisibleChanged: updateGrab()

    Connections {
        target: MenuState
        function onHoldChanged() {
            if (menu.visible)
                menu.updateGrab()
        }
    }

    // Clicks on the bar don't clear the grab, so clicking another indicator
    // switches menus in one click. The bar closes the menu itself (shell.qml).
    HyprlandFocusGrab {
        id: grab
        windows: [menu, menu.anchor.item?.QsWindow.window]
        onCleared: {
            if (!MenuState.hold)
                menu.visible = false
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.background

        // Right-clicking anywhere on the menu closes it. Entries only handle
        // the left button, so the press falls through to here.
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: menu.visible = false
        }

        Column {
            id: column
            anchors.fill: parent
            padding: 12
            spacing: 8

            // Reached from any focused child that doesn't handle Escape itself
            Keys.onEscapePressed: menu.visible = false
        }
    }
}
