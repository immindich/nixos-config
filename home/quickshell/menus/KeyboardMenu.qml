import QtQuick
import Quickshell
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
    // property bindings can follow. The window spans the bar's width, so the
    // frame is moved inside it.
    function place() {
        const p = behavior.placement()
        if (!p)
            return
        frame.x = p.x - frame.pad
        // pos is in the bar window, which sits against the bar's screen edge
        if (Theme.barOnBottom)
            margins.bottom = p.win.height - (p.edge + p.room)
        else
            margins.top = p.edge - p.room
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

    onVisibleChanged: if (visible) place()

    onBackingWindowVisibleChanged: {
        if (backingWindowVisible)
            settle.start()
        else
            mapped = false
    }
    Timer {
        id: settle
        interval: 50
        onTriggered: menu.mapped = menu.backingWindowVisible
    }

    MenuBehavior {
        id: behavior
        menuWindow: menu
        menuFrame: frame
    }

    MenuFrame {
        id: frame
        width: menu.menuWidth + 2 * pad
        height: implicitHeight
    }
}
