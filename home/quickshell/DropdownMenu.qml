import QtQuick
import Quickshell
import Quickshell.Hyprland

// Popup that opens below `anchor.item`, styled like the bar's bubbles.
// Children are stacked vertically. Clicking outside the menu closes it, and
// opening a menu closes any other open one.
PopupWindow {
    id: menu

    default property alias content: column.data

    // Take keyboard input, e.g. for a text field. Uses a Wayland popup grab
    // instead of HyprlandFocusGrab, since a popup only gets the keyboard
    // with the former; clicking anywhere outside the popup closes it.
    property bool takesKeyboard: false
    grabFocus: takesKeyboard

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
    // once the popup is actually on screen
    onBackingWindowVisibleChanged: grab.active = backingWindowVisible && !takesKeyboard

    // Clicks on the bar don't clear the grab, so clicking another indicator
    // switches menus in one click. The bar closes the menu itself (shell.qml).
    HyprlandFocusGrab {
        id: grab
        windows: [menu, menu.anchor.item?.QsWindow.window]
        onCleared: menu.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.background

        Column {
            id: column
            anchors.fill: parent
            padding: 12
            spacing: 8
        }
    }
}
