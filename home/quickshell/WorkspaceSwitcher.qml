import QtQuick
import Quickshell
import Quickshell.Hyprland

// Styled after ashell's Workspaces module (Tokyo Night colors).
// Regular workspaces in one bubble, special workspaces in a second one.
Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.bubbleSpacing

    component Bubble: Rectangle {
        default property alias content: row.data
        implicitWidth: row.implicitWidth + 8
        implicitHeight: Theme.bubbleHeight
        radius: height / 2
        color: Theme.background

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.bubbleSpacing
        }
    }

    component WorkspaceButton: Rectangle {
        required property var modelData
        readonly property var ws: typeof modelData === "number" ? null : modelData
        readonly property bool active: ws !== null && ws.active
        readonly property bool empty: ws === null || ws.toplevels.values.length === 0

        width: active ? 2 * height : Math.max(height, label.implicitWidth + 12)
        height: Theme.workspaceSize
        radius: height / 2
        color: active ? Theme.accent : empty ? Theme.surface : Theme.occupied

        Behavior on width { NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

        Text {
            id: label
            anchors.centerIn: parent
            anchors.verticalCenterOffset: Theme.textOffset
            text: ws ? ws.name.replace(/^special:/, "") : modelData
            font.pixelSize: Theme.fontSize
            color: empty && !active ? Theme.textColor : Theme.background
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
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
        Repeater {
            // Workspaces 1-5 always appear; ones that don't exist yet are
            // plain numbers instead of HyprlandWorkspace objects
            model: ScriptModel {
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
