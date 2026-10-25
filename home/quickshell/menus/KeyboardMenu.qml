import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

// DropdownMenu for menus that take keyboard input, e.g. for a text field.
// It's a layer surface rather than a popup: a popup only gets the keyboard
// through a popup grab, which Wayland refuses until the shell has received
// input, so a menu opened by a keybind right after login wouldn't open.
// Looks and behaves like DropdownMenu: it hangs below `anchor.item`,
// clicking outside or right-clicking inside closes it, and opening it closes
// any other open menu.
PanelWindow {
    id: menu

    default property alias content: column.data

    // Same interface as PopupWindow's anchor, which DropdownMenu uses, so
    // MenuState and the bar can treat both alike. Only `item` is used.
    component MenuAnchor: QtObject {
        property Item item: null
    }
    readonly property MenuAnchor anchor: MenuAnchor {}

    function toggle() {
        menu.visible = !menu.visible
    }

    // Positioned when opened, since an item's position in its window isn't a
    // property bindings can follow
    function place() {
        const item = anchor.item
        if (!item)
            return
        const pos = item.mapToItem(null, (item.width - implicitWidth) / 2, item.height + 8)
        // Kept off the screen edges by the bar's own margin
        margins.left = Math.max(Theme.barMargin, Math.min(pos.x, (screen?.width ?? 0) - implicitWidth - Theme.barMargin))
        margins.top = pos.y
    }

    screen: anchor.item?.QsWindow.window?.screen ?? null
    anchors.top: true
    anchors.left: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-menu"
    // Hyprland gives a layer that takes the keyboard as it maps the pointer
    // too, wherever the cursor is, so the next click would be lost unless
    // the mouse moved first. Dropping from Exclusive to OnDemand once mapped
    // makes it hand the pointer back, and OnDemand keeps the keyboard while
    // letting a click outside clear the focus grab.
    property bool mapped: false
    WlrLayershell.keyboardFocus: mapped ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive

    visible: false
    implicitWidth: 280
    implicitHeight: column.implicitHeight // includes the column's padding
    color: "transparent"

    onVisibleChanged: {
        if (visible) {
            place()
            if (MenuState.openMenu && MenuState.openMenu !== menu)
                MenuState.openMenu.visible = false
            MenuState.openMenu = menu
        } else if (MenuState.openMenu === menu) {
            MenuState.openMenu = null
        }
    }

    // Hyprland rejects a grab on a window that isn't mapped yet, so start it
    // once the menu is actually on screen. Setting it false first re-requests
    // a grab the compositor has already cleared.
    function updateGrab() {
        grab.active = false
        grab.active = backingWindowVisible
    }
    onBackingWindowVisibleChanged: {
        if (backingWindowVisible)
            settle.start()
        else
            mapped = false
        updateGrab()
    }
    Timer {
        id: settle
        interval: 50
        onTriggered: menu.mapped = menu.backingWindowVisible
    }

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
