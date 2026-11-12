import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Panel for trying the colour schemes and look options live, toggled with
// SUPER+SHIFT+T (home/hypr/binds.lua). Each button writes straight to Theme;
// nothing is saved, so a reload of the shell brings back the values in
// Theme.qml. It sits at the bottom of the focused screen (the top with the
// bar at the bottom) so the bar and its menus stay in view, and closes with
// Escape or the key again.
PanelWindow {
    id: tweaker

    property bool shown: false

    function toggle() {
        shown = !shown
    }

    GlobalShortcut { appid: "quickshell"; name: "theme-tweaker"; onPressed: tweaker.toggle() }

    // Each row: the Theme property, its choices and, where the values
    // themselves don't read well, the labels to show for them
    readonly property var settings: [
        { label: "Scheme", prop: "scheme", values: Theme.schemes.map(s => s.name) },
        { label: "Spaces", prop: "workspaceStyle", values: ["", "filled", "tint", "ring", "minimal"], names: ["scheme", "filled", "tint", "ring", "minimal"] },
        { label: "Chosen", prop: "selectionStyle", values: ["", "accent", "row", "check"], names: ["scheme", "accent", "row", "check"] },
        { label: "Fills", prop: "fillStyle", values: ["", "solid", "tint"], names: ["scheme", "solid", "tint"] },
        { label: "Menus", prop: "menuStyle", values: ["flush", "float", "caret", "drawer", "tab"] },
        { label: "Open", prop: "activeStyle", values: ["pill", "filled", "accent", "underline", "tab"] },
        { label: "Outline", prop: "menuBorder", values: [0, 1, 2], names: ["none", "1 px", "2 px"] },
        { label: "Shadow", prop: "menuShadow", values: [false, true], names: ["off", "on"] },
        { label: "Stripe", prop: "menuAccentEdge", values: [false, true], names: ["off", "on"] },
        { label: "Opacity", prop: "menuOpacity", values: [1, 0.85, 0.7, 0.55], names: ["100%", "85%", "70%", "55%"] },
        { label: "Edge", prop: "barPosition", values: ["top", "bottom"] },
        { label: "Size", prop: "fontSize", values: [10, 12, 14, 16, 20] },
    ]

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: shown
    anchors.bottom: !Theme.barOnBottom
    anchors.top: Theme.barOnBottom
    margins.bottom: Theme.px(40)
    margins.top: Theme.px(40)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-tweaker"
    // Clicking the panel gives it the keyboard, for Escape
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    implicitWidth: Theme.px(620)
    // Scrolls rather than reaching the bar when the rows don't fit (at a
    // large size)
    implicitHeight: Math.min(column.implicitHeight, (screen?.height ?? 0) - Theme.barHeight - 2 * Theme.px(40))
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.px(12)
        color: Theme.menuColor
        border.width: Theme.menuBorder
        border.color: Theme.borderColor

        focus: true
        Keys.onEscapePressed: tweaker.shown = false

        Flickable {
            anchors.fill: parent
            contentHeight: column.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: column
                width: parent.width
                padding: Theme.px(12)
                spacing: Theme.px(6)

                Repeater {
                    model: tweaker.settings

                    Row {
                        id: row
                        required property var modelData
                        spacing: Theme.px(8)

                        Text {
                            width: Theme.px(64)
                            anchors.top: parent.top
                            topPadding: Theme.px(4)
                            text: row.modelData.label
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            color: Theme.textColor
                        }

                        Flow {
                            width: column.width - 2 * column.padding - Theme.px(64) - row.spacing
                            spacing: Theme.px(4)

                            Repeater {
                                model: row.modelData.values

                                Rectangle {
                                    id: choice
                                    required property var modelData
                                    required property int index
                                    readonly property bool selected: Theme[row.modelData.prop] === modelData

                                    width: label.implicitWidth + Theme.px(16)
                                    height: Theme.px(24)
                                    radius: height / 2
                                    color: selected ? Theme.controlFill : hover.hovered ? Theme.highlight : Theme.surface

                                    Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

                                    Text {
                                        id: label
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: Theme.textOffset
                                        text: row.modelData.names ? row.modelData.names[choice.index] : choice.modelData
                                        font.pixelSize: Theme.fontSize - Theme.px(1)
                                        color: choice.selected ? Theme.controlText : Theme.textColor
                                    }

                                    HoverHandler { id: hover }
                                    TapHandler { onTapped: Theme[row.modelData.prop] = choice.modelData }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
