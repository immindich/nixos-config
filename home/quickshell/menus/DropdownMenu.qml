import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// Popup that opens below `anchor.item` (above it with the bar at the bottom), styled like the bar's bubbles.
// Children are stacked vertically. Menus that take keyboard input use
// KeyboardMenu instead. Clicking outside the menu or right-clicking
// inside it closes it, and opening a menu closes any other open one.
PopupWindow {
    id: menu

    default property alias content: frame.content
    // Width of the panel; the window is wider by the shadow's room
    property int menuWidth: Theme.px(280)

    anchor.rect.width: Theme.px(1)
    anchor.rect.height: Theme.px(1)
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: (Theme.barOnBottom ? Edges.Top : Edges.Bottom) | Edges.Right
    // Positioned by place(), which keeps the panel on screen itself
    anchor.adjustment: PopupAdjustment.None
    anchor.onAnchoring: place()

    implicitWidth: menuWidth + 2 * frame.pad
    implicitHeight: frame.implicitHeight
    color: "transparent"
    // Clicks on the shadow's room go through to what's underneath
    mask: Region { item: frame.panel }

    // Hang off the bar, centered on the anchor item; slid back on screen if
    // it would go past the edge, keeping the bar's margin from it. Where the
    // panel sits relative to the bar depends on Theme.menuStyle.
    function place() {
        const item = anchor.item
        if (!item)
            return
        const win = item.QsWindow.window
        const pos = item.mapToItem(null, 0, 0)
        const want = pos.x + (item.width - frame.panelWidth) / 2
        const x = Math.max(Theme.barMargin, Math.min(want, win.width - frame.panelWidth - Theme.barMargin))
        frame.caretOffset = want - x
        anchor.rect.x = x - frame.pad - pos.x
        // Edge of the panel that faces the bar, in the bar window's coordinates
        let edge
        if (Theme.menuStyle === "flush")
            edge = Theme.barOnBottom ? pos.y - Theme.px(8) : pos.y + item.height + Theme.px(8)
        else {
            const inset = Theme.menuStyle === "float" || Theme.menuStyle === "caret" ? Theme.menuGap : 0
            edge = Theme.barOnBottom ? -inset : Theme.barHeight + inset
        }
        const room = frame.pad + frame.caretSize
        anchor.rect.y = (Theme.barOnBottom ? edge + room : edge - room) - pos.y
    }

    // Tallest the content can be before the menu runs off the far edge of
    // the screen, for menus that scroll a long list. The menu hangs just off
    // the bar and keeps the bar's margin from the far edge.
    readonly property int maxContentHeight: (anchor.item?.QsWindow.window?.screen?.height ?? 0)
        - Theme.barHeight - Theme.menuGap - Theme.barMargin - 2 * frame.column.padding

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

    MenuFrame {
        id: frame
        anchors.fill: parent
        onCloseRequested: menu.visible = false
    }
}
