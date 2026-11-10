import QtQuick
import Quickshell
import qs

// Popup that opens below `anchor.item` (above it with the bar at the bottom)
// in a MenuFrame, which draws it the way Theme.menuStyle asks. Children are
// stacked vertically. Menus that take keyboard input use
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
    // The window reaches the far edge of the screen whatever the content's
    // height, with the panel at the end facing the bar and the rest left
    // transparent. Resizing a popup every frame, as an unfolding section
    // would, makes Hyprland show some frames offset by the change, so the
    // whole menu jumps.
    implicitHeight: Math.max(frame.implicitHeight, roomHeight)
    // Height from the panel's bar-facing edge to the far edge of the screen,
    // with the frame's room for shadow and caret; set by place()
    property int roomHeight: 0
    color: "transparent"
    // Clicks on the shadow's room go through to what's underneath
    mask: Region { item: frame.panel }

    // Hang off the bar where MenuBehavior says. The window reaches the far
    // edge of the screen (see implicitHeight).
    function place() {
        const p = behavior.placement()
        if (!p)
            return
        anchor.rect.x = p.x - frame.pad - p.pos.x
        anchor.rect.y = (Theme.barOnBottom ? p.edge + p.room : p.edge - p.room) - p.pos.y
        // The bar's window sits flush with its edge of the screen
        const screenHeight = p.win.screen?.height ?? 0
        const winTop = Theme.barOnBottom ? screenHeight - p.win.height : 0
        roomHeight = Theme.barOnBottom ? winTop + p.edge + p.room
            : screenHeight - (winTop + p.edge - p.room)
    }

    // Tallest the content can be before the menu runs off the far edge of
    // the screen, for menus that scroll a long list. The menu hangs just off
    // the bar and keeps the bar's margin from the far edge.
    readonly property int maxContentHeight: (anchor.item?.QsWindow.window?.screen?.height ?? 0)
        - Theme.barHeight - Theme.menuGap - Theme.barMargin - 2 * frame.column.padding

    function toggle() {
        menu.visible = !menu.visible
    }

    MenuBehavior {
        id: behavior
        menuWindow: menu
        menuFrame: frame
    }

    MenuFrame {
        id: frame
        anchors.fill: parent
    }
}
