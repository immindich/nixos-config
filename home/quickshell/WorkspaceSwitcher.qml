import QtQuick
import Quickshell
import Quickshell.Hyprland

// Styled after ashell's Workspaces module (Tokyo Night colors).
// Regular workspaces in one bubble, special workspaces in a second one.
// Each bar lists the regular workspaces on its own monitor; the special ones
// can be opened on any monitor, so every bar lists all of them.
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

    // Workspaces above this id hold fullscreen windows, one each
    // (home/hyprland.nix moves them there)
    readonly property int fullscreenBase: 100

    // Icons for the special workspaces: the test VM (modules/vm.nix) gets a
    // cube, anything else the magic wand
    readonly property var specialIcons: ({
        "special:vm": "\uf1b2" // cube
    })

    // The monitor this bar is on. Looked up by name rather than with
    // Hyprland.monitorFor() so it updates when the monitor list does.
    readonly property HyprlandMonitor monitor: {
        const name = QsWindow.window?.screen?.name
        return Hyprland.monitors.values.find(m => m.name === name) ?? null
    }

    // Name of the special workspace open on this monitor, if any;
    // HyprlandWorkspace.active doesn't cover them
    readonly property string openSpecial: monitor?.lastIpcObject?.specialWorkspace?.name ?? ""

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
            && (special ? switcher.openSpecial === ws.name : ws.active)
        readonly property bool empty: ws === null || ws.toplevels.values.length === 0
        readonly property bool fullscreen: ws !== null && ws.id > switcher.fullscreenBase

        width: active ? 2 * height : special ? height : Math.max(height, label.implicitWidth + 12)
        height: Theme.workspaceSize
        radius: height / 2
        color: active ? Theme.accent : empty ? Theme.surface : Theme.occupied

        Behavior on width { NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

        // The number; fullscreen workspaces (see fullscreenBase) count from 1
        // after an icon
        Row {
            id: label
            anchors.centerIn: parent
            visible: !special
            spacing: 3

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: fullscreen
                text: "\uf065" // expand
                font.family: Theme.iconFont
                font.weight: Font.Black
                font.pixelSize: Theme.iconSize - 2
                color: Theme.background
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                text: fullscreen ? ws.id - switcher.fullscreenBase : ws ? ws.name : modelData
                font.pixelSize: Theme.fontSize
                color: empty && !active ? Theme.textColor : Theme.background
            }
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
            // The workspaces on this monitor, plus whichever of 1-5 don't
            // exist on any monitor yet, as plain numbers instead of
            // HyprlandWorkspace objects; clicking one creates it here
            model: ScriptModel {
                id: regularModel
                values: {
                    const all = Hyprland.workspaces.values.filter(ws => !ws.name.startsWith("special:"))
                    const regular = all.filter(ws => ws.monitor !== null && ws.monitor === switcher.monitor)
                    for (let id = 1; id <= 5; id++) {
                        if (!all.some(ws => ws.id === id))
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
