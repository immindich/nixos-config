import QtQuick
import Quickshell
import Quickshell.Hyprland

// Styled after ashell's Workspaces module (Tokyo Night colors).
// Regular workspaces in one bubble, special workspaces in a second one.
// Scrolling on the regular bubble steps through the workspaces it shows.
// Resting the pointer on a workspace lists its windows below it.
Row {
    id: switcher
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.bubbleSpacing

    WorkspaceWindows { id: windows }

    // Focus the workspace `direction` places along the regular bubble from
    // the active one (up = previous, down = next); stops at the ends
    function step(direction) {
        const shown = regularModel.values
        const active = shown.find(w => typeof w !== "number" && w.active)
        if (!active)
            return
        const index = shown.indexOf(active) - direction
        if (index < 0 || index >= shown.length)
            return
        const target = shown[index]
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + (typeof target === "number" ? target : target.id) + " })")
    }

    // Icons for the special workspaces: the test VM (modules/vm.nix) gets a
    // cube, anything else the magic wand
    readonly property var specialIcons: ({
        "special:vm": "\uf1b2" // cube
    })

    // Names of the special workspaces open on any monitor, as in WindowTitle;
    // HyprlandWorkspace.active doesn't cover them
    readonly property var openSpecials: Hyprland.monitors.values
        .map(m => m.lastIpcObject?.specialWorkspace?.name ?? "")
        .filter(name => name !== "")

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial")
                Hyprland.refreshMonitors()
        }
    }

    component Bubble: Rectangle {
        default property alias content: row.data
        // Scroll wheel notches on the bubble (1 = up, -1 = down)
        signal scrolled(int direction)
        implicitWidth: row.implicitWidth + 8
        implicitHeight: Theme.bubbleHeight
        radius: height / 2
        color: Theme.background

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.bubbleSpacing
        }

        WheelSteps { onStepped: direction => scrolled(direction) }
    }

    component WorkspaceButton: Rectangle {
        id: button
        required property var modelData
        readonly property var ws: typeof modelData === "number" ? null : modelData
        // Special workspaces show an icon instead of their name
        readonly property bool special: ws !== null && ws.name.startsWith("special:")
        readonly property bool active: ws !== null
            && (special ? switcher.openSpecials.includes(ws.name) : ws.active)
        readonly property bool empty: ws === null || ws.toplevels.values.length === 0

        width: active ? 2 * height : special ? height : Math.max(height, label.implicitWidth + 12)
        height: Theme.workspaceSize
        radius: height / 2
        color: active ? Theme.accent : empty ? Theme.surface : Theme.occupied

        Behavior on width { NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

        Text {
            id: label
            anchors.centerIn: parent
            anchors.verticalCenterOffset: Theme.textOffset
            visible: !special
            text: ws ? ws.name : modelData
            font.pixelSize: Theme.fontSize
            color: empty && !active ? Theme.textColor : Theme.background
        }

        Text {
            anchors.centerIn: parent
            visible: special
            text: special ? (switcher.specialIcons[ws.name] ?? "\ue2ca") : "" // wand-magic-sparkles
            font.family: Theme.iconFont
            font.weight: Font.Black
            font.pixelSize: Theme.iconSize
            color: Theme.background
        }

        HoverHandler {
            onHoveredChanged: hovered ? windows.hover(button) : windows.unhover(button)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                windows.dismiss()
                if (!ws)
                    Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData + " })")
                else if (ws.name.startsWith("special:"))
                    Hyprland.dispatch("hl.dsp.workspace.toggle_special(" + JSON.stringify(ws.name.slice("special:".length)) + ")")
                else
                    ws.activate()
            }
        }
    }

    Bubble {
        onScrolled: direction => switcher.step(direction)

        Repeater {
            // Workspaces 1-5 always appear; ones that don't exist yet are
            // plain numbers instead of HyprlandWorkspace objects
            model: ScriptModel {
                id: regularModel
                values: {
                    const regular = Hyprland.workspaces.values.filter(ws => !ws.name.startsWith("special:"))
                    for (let id = 1; id <= 5; id++) {
                        if (!regular.some(ws => ws.id === id))
                            regular.push(id)
                    }
                    const idOf = w => typeof w === "number" ? w : w.id
                    regular.sort((a, b) => idOf(a) - idOf(b))
                    return regular
                }
            }
            WorkspaceButton {}
        }
    }

    Bubble {
        visible: specialModel.values.length > 0

        Repeater {
            model: ScriptModel {
                id: specialModel
                values: Hyprland.workspaces.values.filter(ws => ws.name.startsWith("special:"))
            }
            WorkspaceButton {}
        }
    }
}
