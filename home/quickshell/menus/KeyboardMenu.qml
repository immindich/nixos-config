import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

// DropdownMenu for menus that take keyboard input, e.g. for a text field.
// It's a layer surface rather than a popup: a popup only gets the keyboard
// through a popup grab, which Wayland refuses until the shell has received
// input, so a menu opened by a keybind right after login wouldn't open.
// Looks and behaves like DropdownMenu: it hangs off `anchor.item`,
// clicking outside or right-clicking inside closes it, and opening it closes
// any other open menu.
PanelWindow {
    id: menu

    default property alias content: frame.content
    // Width of the panel; the window spans the bar
    property int menuWidth: Theme.px(280)

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
    // property bindings can follow. Same placement as DropdownMenu.place(),
    // but the window spans the bar's width and the frame is moved inside it.
    function place() {
        const item = anchor.item
        if (!item)
            return
        const win = item.QsWindow.window
        const pos = item.mapToItem(null, 0, 0)
        const want = pos.x + (item.width - menuWidth) / 2
        const x = Math.max(Theme.barMargin, Math.min(want, win.width - menuWidth - Theme.barMargin))
        frame.caretOffset = want - x
        frame.x = x - frame.pad
        let edge
        if (Theme.menuStyle === "flush")
            edge = Theme.barOnBottom ? pos.y - Theme.px(8) : pos.y + item.height + Theme.px(8)
        else {
            const inset = Theme.menuStyle === "float" || Theme.menuStyle === "caret" ? Theme.menuGap : 0
            edge = Theme.barOnBottom ? -inset : Theme.barHeight + inset
        }
        const room = frame.pad + frame.caretSize
        // pos is in the bar window, which sits against the bar's screen edge
        if (Theme.barOnBottom)
            margins.bottom = win.height - (edge + room)
        else
            margins.top = edge - room
    }

    screen: anchor.item?.QsWindow.window?.screen ?? null
    anchors.top: !Theme.barOnBottom
    anchors.bottom: Theme.barOnBottom
    anchors.left: true
    anchors.right: true
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
    implicitHeight: frame.implicitHeight
    color: "transparent"
    // Only the panel takes input; clicks beside it go through
    mask: Region { item: frame.panel }

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

    MenuFrame {
        id: frame
        width: menu.menuWidth + 2 * pad
        height: implicitHeight
        onCloseRequested: menu.visible = false
    }
}
