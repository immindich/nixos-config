import QtQuick
import qs

// Pill behind a bar indicator that marks its menu being open (`lit`) the
// way Theme.activeStyle asks for. Glyphs drawn in it should take their
// colour from `fgColor`.
Rectangle {
    id: pill

    property bool lit: false
    // Colour of the glyphs while the menu is closed
    property color contentColor: Theme.textColor
    // Width of the underline, when that's the style
    property int underlineWidth: width - Theme.px(12)

    readonly property string style: Theme.activeStyle
    readonly property color fgColor: !lit ? contentColor
        : style === "filled" ? Theme.background
        : style === "accent" ? Theme.accent
        : contentColor

    radius: height / 2
    color: !lit ? "transparent"
        : style === "pill" ? Theme.highlight
        : style === "filled" ? Theme.accent
        : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

    // Tab: a browser-style tab from the bubble's edge to the bar's edge,
    // joined to the menu, which is flush with the bar (MenuFrame)
    Rectangle {
        visible: pill.lit && pill.style === "tab"
        x: -Theme.px(3)
        width: parent.width + 2 * Theme.px(3)
        height: Theme.barHeight - Theme.barMargin
        y: Theme.barOnBottom ? parent.height / 2 + Theme.bubbleHeight / 2 - height : parent.height / 2 - Theme.bubbleHeight / 2
        radius: Theme.px(8)
        topLeftRadius: Theme.barOnBottom ? 0 : radius
        topRightRadius: Theme.barOnBottom ? 0 : radius
        bottomLeftRadius: Theme.barOnBottom ? radius : 0
        bottomRightRadius: Theme.barOnBottom ? radius : 0
        color: Theme.menuColor
        border.width: Theme.menuBorder
        border.color: Theme.borderColor

        // No outline where it meets the menu
        Rectangle {
            x: Theme.menuBorder
            width: parent.width - 2 * Theme.menuBorder
            height: Theme.menuBorder
            y: Theme.barOnBottom ? 0 : parent.height - height
            color: parent.color
        }
    }

    // Underline: an accent stroke along the edge facing the menu
    Rectangle {
        visible: pill.lit && pill.style === "underline"
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.barOnBottom ? 0 : parent.height - height
        width: pill.underlineWidth
        height: Theme.px(2)
        radius: height / 2
        color: Theme.accent
    }
}
