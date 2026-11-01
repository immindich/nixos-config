import QtQuick
import QtQuick.Effects
import qs

// Surface of a menu: the rounded panel with the outline, shadow and caret
// the theme asks for. Fills the menu window. `pad` is the transparent room
// left around the panel for its shadow, `caretSize` the room above it
// (below it with the bar at the bottom) for the caret.
Item {
    id: frame

    default property alias content: column.data
    readonly property alias column: column
    readonly property alias panel: panel
    // How far the caret sits from the panel's center, for a panel that was
    // slid back on screen (set by the menu)
    property real caretOffset: 0
    signal closeRequested()

    readonly property int pad: Theme.menuShadow ? Theme.px(20) : 0
    readonly property int caretSize: Theme.menuStyle === "caret" ? Theme.px(8) : 0
    readonly property bool squareTop: Theme.menuStyle === "drawer" || Theme.menuStyle === "tab"
    readonly property int panelWidth: width - 2 * pad
    readonly property int panelHeight: column.implicitHeight

    implicitHeight: panelHeight + 2 * pad + caretSize

    Rectangle {
        id: panel
        x: frame.pad
        y: frame.pad + (Theme.barOnBottom ? 0 : frame.caretSize)
        width: frame.panelWidth
        height: frame.panelHeight
        radius: Theme.px(12)
        topLeftRadius: frame.squareTop && !Theme.barOnBottom ? 0 : radius
        topRightRadius: frame.squareTop && !Theme.barOnBottom ? 0 : radius
        bottomLeftRadius: frame.squareTop && Theme.barOnBottom ? 0 : radius
        bottomRightRadius: frame.squareTop && Theme.barOnBottom ? 0 : radius
        color: Qt.rgba(Theme.menuColor.r, Theme.menuColor.g, Theme.menuColor.b, Theme.menuOpacity)
        border.width: Theme.menuBorder
        border.color: Theme.borderColor

        // Right-clicking anywhere on the menu closes it. Entries only handle
        // the left button, so the press falls through to here.
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: frame.closeRequested()
        }

        Column {
            id: column
            anchors.fill: parent
            padding: Theme.px(12)
            spacing: Theme.px(8)

            // Reached from any focused child that doesn't handle Escape itself
            Keys.onEscapePressed: frame.closeRequested()
        }

        // Accent stripe along the edge facing the bar
        Rectangle {
            visible: Theme.menuAccentEdge
            x: Theme.menuBorder
            width: parent.width - 2 * Theme.menuBorder
            height: Theme.px(2)
            y: Theme.barOnBottom ? parent.height - height - Theme.menuBorder : Theme.menuBorder
            color: Theme.accent
        }

        // A drawer has no outline along the edge that meets the bar
        Rectangle {
            visible: frame.squareTop && Theme.menuBorder > 0
            x: Theme.menuBorder
            width: parent.width - 2 * Theme.menuBorder
            height: Theme.menuBorder
            y: Theme.barOnBottom ? parent.height - height : 0
            color: panel.color
        }
    }

    // Drop shadow, drawn under the panel. A drawer's shadow stops at the bar.
    Item {
        z: -1
        clip: frame.squareTop
        x: 0
        width: frame.width
        y: frame.squareTop && !Theme.barOnBottom ? panel.y : 0
        height: frame.squareTop && Theme.barOnBottom ? panel.y + panel.height : frame.height - y

        MultiEffect {
            visible: Theme.menuShadow
            source: panel
            x: panel.x
            y: panel.y - parent.y
            width: panel.width
            height: panel.height
            shadowEnabled: true
            shadowBlur: 1
            shadowColor: "black"
            shadowOpacity: 0.7
            shadowVerticalOffset: (Theme.barOnBottom ? -1 : 1) * Theme.px(4)
        }
    }

    // Caret pointing at the indicator: a rotated square centered on the
    // panel's edge, clipped to the half outside it plus the panel's outline,
    // which it covers
    Item {
        visible: frame.caretSize > 0
        clip: true
        readonly property int size: frame.caretSize
        readonly property real border: Theme.menuBorder * Math.SQRT2
        x: panel.x + panel.width / 2 + frame.caretOffset - width / 2
        width: 2 * (size + border) + Theme.px(4)
        height: size + Theme.menuBorder
        y: Theme.barOnBottom ? panel.y + panel.height - Theme.menuBorder : panel.y - size

        Rectangle {
            visible: Theme.menuBorder > 0
            anchors.centerIn: parent
            anchors.verticalCenterOffset: (Theme.barOnBottom ? -1 : 1) * (parent.size - Theme.menuBorder) / 2
            width: (parent.size + parent.border) * Math.SQRT2
            height: width
            rotation: 45
            color: Theme.borderColor
        }
        Rectangle {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: (Theme.barOnBottom ? -1 : 1) * (parent.size - Theme.menuBorder) / 2
            width: parent.size * Math.SQRT2
            height: width
            rotation: 45
            color: panel.color
        }
    }
}
