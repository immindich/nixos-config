import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Prompt box for Claude Desktop, in the middle of the focused screen, opened
// by the claude-prompt global shortcut (its SUPER+A bind in home/hyprland.nix
// is commented out for now). Enter starts a new chat in Claude with
// the text through a claude://claude.ai/new?q= deep link, which fills in the
// message box, and brings Claude's window (kept on special:magic) into view.
// Shift+Enter adds a line. Escape or a click elsewhere closes it and keeps
// the draft.
PanelWindow {
    id: prompt

    property bool shown: false

    function open() {
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        shown = true
    }

    function send() {
        const text = input.text.trim()
        if (text === "")
            return
        // Passed as an argument, not through a shell, and percent-encoded, so
        // the text can't change the link
        Quickshell.execDetached(["xdg-open", "claude://claude.ai/new?q=" + encodeURIComponent(text)])
        // A fixed expression: shows the scratchpad Claude lives on, unless
        // it's already shown
        Hyprland.dispatch(`(function()
            local special = hl.get_active_special_workspace()
            if special and special.name == "special:magic" then return hl.dsp.no_op() end
            return hl.dsp.workspace.toggle_special("magic")
        end)()`)
        input.text = ""
        shown = false
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "claude-prompt"
        onPressed: {
            if (prompt.shown)
                prompt.shown = false
            else
                prompt.open()
        }
    }

    visible: shown
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-claude-prompt"
    // As in KeyboardMenu: Hyprland gives a layer that takes the keyboard as
    // it maps the pointer too, so drop from Exclusive to OnDemand once mapped
    // to hand the pointer back
    property bool mapped: false
    WlrLayershell.keyboardFocus: mapped ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive
    implicitWidth: 560
    implicitHeight: column.implicitHeight
    color: "transparent"

    onBackingWindowVisibleChanged: {
        if (backingWindowVisible) {
            settle.start()
            input.forceActiveFocus()
        } else {
            mapped = false
        }
        grab.active = backingWindowVisible
    }
    Timer {
        id: settle
        interval: 50
        onTriggered: prompt.mapped = prompt.backingWindowVisible
    }

    // A click outside closes it
    HyprlandFocusGrab {
        id: grab
        windows: [prompt]
        onCleared: prompt.shown = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.background

        Column {
            id: column
            width: parent.width
            padding: 12
            spacing: 8

            Text {
                text: "Ask Claude"
                font.pixelSize: Theme.fontSize
                font.bold: true
                color: Theme.textColor
            }

            Rectangle {
                width: parent.width - parent.leftPadding - parent.rightPadding
                // Grows with the text up to ten lines, then scrolls
                height: Math.min(input.implicitHeight, input.font.pixelSize * 1.4 * 10) + 16
                radius: 8
                color: Theme.surface
                border.width: input.activeFocus ? 1 : 0
                border.color: Theme.accent

                Flickable {
                    id: flick
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    contentWidth: width
                    contentHeight: input.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextEdit {
                        id: input
                        width: flick.width
                        textFormat: TextEdit.PlainText
                        wrapMode: TextEdit.Wrap
                        font.pixelSize: Theme.fontSize
                        color: Theme.textColor
                        selectionColor: Theme.accent
                        selectByMouse: true

                        // Keep the cursor in view as the text scrolls
                        onCursorRectangleChanged: {
                            const r = cursorRectangle
                            if (r.y < flick.contentY)
                                flick.contentY = r.y
                            else if (r.y + r.height > flick.contentY + flick.height)
                                flick.contentY = r.y + r.height - flick.height
                        }

                        // Enter sends; Shift+Enter falls through to the
                        // TextEdit, which adds a line
                        Keys.onReturnPressed: event => {
                            if (event.modifiers & Qt.ShiftModifier)
                                event.accepted = false
                            else
                                prompt.send()
                        }
                        Keys.onEnterPressed: event => {
                            if (event.modifiers & Qt.ShiftModifier)
                                event.accepted = false
                            else
                                prompt.send()
                        }
                        Keys.onEscapePressed: prompt.shown = false

                        Text {
                            visible: input.text === ""
                            text: "Message Claude"
                            font.pixelSize: Theme.fontSize
                            color: Theme.dimTextColor
                        }
                    }
                }
            }

            Text {
                text: "Enter to send · Shift+Enter for a new line"
                font.pixelSize: Theme.fontSize - 2
                color: Theme.dimTextColor
            }
        }
    }
}
