import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// What DropdownMenu and KeyboardMenu have in common, whatever kind of window
// they are: where the panel hangs off the bar, only one menu open at a time,
// and closing on a click outside or right-click inside.
Scope {
    id: behavior

    // The menu window: a DropdownMenu or KeyboardMenu
    required property var menuWindow
    required property MenuFrame menuFrame

    // Where the panel goes: centered on the anchor item, slid back on screen
    // if it would go past the edge, keeping the bar's margin from it; how far
    // it sits from the bar depends on Theme.menuStyle. Points the caret at
    // the item. Returns, in the bar window's coordinates, the panel's left
    // edge `x` and its bar-facing edge `edge`, along with the bar window
    // `win`, the item's position `pos` in it, and `room`, the frame's space
    // beyond the panel's bar-facing edge for shadow and caret. Null while the
    // menu has no anchor item.
    function placement() {
        const item = menuWindow.anchor.item
        if (!item)
            return null
        const win = item.QsWindow.window
        // Measured from the window's top-level item rather than the window,
        // so a bar still sliding in (a menu opened by keybind over a
        // fullscreen window) gives the position it's about to settle at
        let top = item
        while (top.parent && top.parent !== win.contentItem)
            top = top.parent
        const pos = item.mapToItem(top, 0, 0)
        const want = pos.x + (item.width - menuWindow.menuWidth) / 2
        const x = Math.max(Theme.barMargin, Math.min(want, win.width - menuWindow.menuWidth - Theme.barMargin))
        menuFrame.caretOffset = want - x
        let edge
        if (Theme.menuStyle === "flush")
            edge = Theme.barOnBottom ? pos.y - Theme.px(8) : pos.y + item.height + Theme.px(8)
        else
            edge = Theme.barOnBottom ? -menuFrame.barInset : Theme.barHeight + menuFrame.barInset
        return { win, pos, x, edge, room: menuFrame.pad + menuFrame.caretSize }
    }

    // Hyprland rejects a grab on a window that isn't mapped yet, so start it
    // once the menu is actually on screen. Setting it false first re-requests
    // a grab the compositor has already cleared.
    function updateGrab() {
        grab.active = false
        grab.active = menuWindow.backingWindowVisible
    }

    Connections {
        target: behavior.menuWindow

        // Opening a menu closes any other open one
        function onVisibleChanged() {
            const menu = behavior.menuWindow
            if (menu.visible) {
                behavior.menuFrame.playOpen()
                if (MenuState.openMenu && MenuState.openMenu !== menu)
                    MenuState.openMenu.visible = false
                MenuState.openMenu = menu
            } else if (MenuState.openMenu === menu) {
                MenuState.openMenu = null
            }
        }

        function onBackingWindowVisibleChanged() { behavior.updateGrab() }
    }

    Connections {
        target: behavior.menuFrame
        function onCloseRequested() { behavior.menuWindow.visible = false }
    }

    Connections {
        target: MenuState
        function onHoldChanged() {
            if (behavior.menuWindow.visible)
                behavior.updateGrab()
        }
    }

    // Clicks on the bar don't clear the grab, so clicking another indicator
    // switches menus in one click. The bar closes the menu itself (shell.qml).
    HyprlandFocusGrab {
        id: grab
        windows: [behavior.menuWindow, behavior.menuWindow.anchor.item?.QsWindow.window]
        onCleared: {
            if (!MenuState.hold)
                behavior.menuWindow.visible = false
        }
    }
}
