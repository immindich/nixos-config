import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import qs

// Start menu, opened from the NixOS button: an application search field
// (type, pick with Up/Down, launch with Enter) above two rows of session
// buttons: lock, sleep and hibernate, then shut down, restart and log out,
// which ask for confirmation first. Tab cycles between the search field and
// the buttons.
// Set `anchor.item` to the button.
KeyboardMenu {
    id: sessionMenu
    menuWidth: Theme.px(300)

    // Action awaiting confirmation, or null while showing the buttons
    property var pending: null
    // Button that set `pending`, to give focus back to on Cancel
    property Item pendingButton: null

    // Index of the highlighted search result
    property int selected: 0

    onVisibleChanged: {
        pending = null
        searchInput.text = ""
        if (visible)
            searchInput.forceActiveFocus()
    }

    // Pausing the session on top, ending it below
    readonly property var actionRows: [
        [
            { icon: "\uf023", label: "Lock", command: "loginctl lock-session", confirm: false }, // lock
            { icon: "\uf186", label: "Sleep", command: "systemctl suspend", confirm: false }, // moon
            { icon: "\uf2dc", label: "Hibernate", command: "systemctl hibernate", confirm: false }, // snowflake
        ],
        [
            { icon: "\uf011", label: "Shut down", command: "systemctl poweroff", confirm: true }, // power-off
            { icon: "\uf2f9", label: "Restart", command: "systemctl reboot", confirm: true }, // rotate-right
            // Same as the SUPER+M bind
            { icon: "\uf2f5", label: "Log out", confirm: true, // right-from-bracket
              command: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'" },
        ],
    ]

    // Applications matching the search, best first: names starting with the
    // query, then names containing it, then generic name or keyword matches
    readonly property var results: {
        const query = searchInput.text.trim().toLowerCase()
        if (query === "")
            return []
        const matches = []
        for (const entry of DesktopEntries.applications.values) {
            if (entry.noDisplay)
                continue
            const name = entry.name.toLowerCase()
            let rank
            if (name.startsWith(query))
                rank = 0
            else if (name.includes(query))
                rank = 1
            else if (entry.genericName.toLowerCase().includes(query)
                     || Array.from(entry.keywords).some(k => k.toLowerCase().includes(query)))
                rank = 2
            else
                continue
            matches.push({ entry, rank })
        }
        matches.sort((a, b) => a.rank - b.rank || a.entry.name.localeCompare(b.entry.name))
        return matches.slice(0, 8).map(m => m.entry)
    }

    // A new list of results puts fresh rows under the pointer, which report
    // being hovered without it moving. Until the pointer actually moves, keep
    // the selection on the top result instead of following it.
    property bool pointerStill: false
    property point stillAt

    onResultsChanged: {
        selected = 0
        pointerStill = true
        stillAt = menuHover.point.scenePosition
    }

    HoverHandler {
        id: menuHover
        onPointChanged: {
            const at = point.scenePosition
            if (!sessionMenu.pointerStill || (at.x === sessionMenu.stillAt.x && at.y === sessionMenu.stillAt.y))
                return
            sessionMenu.pointerStill = false
            for (let i = 0; i < resultRows.count; i++) {
                if (resultRows.itemAt(i)?.hovered)
                    sessionMenu.selected = i
            }
        }
    }

    // `qs ipc call startmenu toggle`, bound to the Super key in Hyprland.
    // Only the menu on the focused screen answers.
    IpcHandler {
        target: "startmenu"
        enabled: sessionMenu.anchor.item?.QsWindow.window?.screen?.name === Hyprland.focusedMonitor?.name
        function toggle(): void { sessionMenu.toggle() }
    }

    function run(action) {
        sessionMenu.visible = false
        Quickshell.execDetached(["sh", "-c", action.command])
    }

    function launch(entry) {
        sessionMenu.visible = false
        // execute() ignores Terminal=true, so wrap those in kitty ourselves.
        // systemd-run gives the app its own scope; otherwise it stays in
        // quickshell.service's cgroup and is killed when the shell restarts.
        const command = entry.runInTerminal ? ["kitty", "--"].concat(entry.command) : entry.command
        Quickshell.execDetached({
            command: ["systemd-run", "--user", "--scope", "--slice=app.slice", "--collect", "--"].concat(command),
            workingDirectory: entry.workingDirectory
        })
    }

    // Rounded button with an optional Font Awesome icon before its label, or
    // above it if `stacked`; content is left-aligned unless `centered`.
    // Reachable with Tab and pressed with Enter or Space.
    component MenuButton: Rectangle {
        id: button
        property alias icon: iconText.text
        property alias text: labelText.text
        property color contentColor: Theme.textColor
        property bool centered: false
        property bool stacked: false
        signal clicked()

        implicitHeight: stacked ? Theme.px(52) : Theme.px(28)
        radius: stacked ? Theme.px(12) : height / 2
        color: hover.hovered ? Theme.highlight : Theme.surface
        border.width: activeFocus ? 1 : 0
        border.color: Theme.accent

        activeFocusOnTab: true
        Keys.onReturnPressed: button.clicked()
        Keys.onEnterPressed: button.clicked()
        Keys.onSpacePressed: button.clicked()

        Grid {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: button.centered ? parent.horizontalCenter : undefined
            anchors.left: button.centered ? undefined : parent.left
            anchors.leftMargin: Theme.px(12)
            columns: button.stacked ? 1 : 2
            columnSpacing: Theme.px(10)
            rowSpacing: Theme.px(6)
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            Text {
                id: iconText
                visible: text !== ""
                width: Theme.px(16)
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.iconFont
                font.weight: Font.Black
                font.pixelSize: Theme.iconSize
                color: button.contentColor
            }

            Text {
                id: labelText
                visible: text !== ""
                transform: Translate { y: Theme.textOffset }
                font.pixelSize: Theme.fontSize
                color: button.contentColor
            }
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: button.clicked() }
    }

    // Search field
    SearchField {
        id: searchInput
        placeholder: "Search applications"
        activeFocusOnTab: true
        onAccepted: {
            const entry = sessionMenu.results[sessionMenu.selected]
            if (entry)
                sessionMenu.launch(entry)
        }
        onUpPressed: sessionMenu.selected = Math.max(sessionMenu.selected - 1, 0)
        onDownPressed: sessionMenu.selected = Math.min(sessionMenu.selected + 1, sessionMenu.results.length - 1)
    }

    // Search results
    Repeater {
        id: resultRows
        model: sessionMenu.results

        Rectangle {
            id: result
            required property var modelData
            required property int index
            readonly property bool hovered: rowHover.hovered
            width: parent.width - parent.leftPadding - parent.rightPadding
            height: Theme.px(32)
            radius: Theme.px(8)
            // Only while Enter would launch it
            color: index === sessionMenu.selected && searchInput.activeFocus ? Theme.highlight : "transparent"

            IconImage {
                id: appIcon
                anchors.left: parent.left
                anchors.leftMargin: Theme.px(8)
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: Theme.px(20)
                source: Quickshell.iconPath(result.modelData.icon, "application-x-executable")
            }

            Text {
                anchors.left: appIcon.right
                anchors.leftMargin: Theme.px(10)
                anchors.right: parent.right
                anchors.rightMargin: Theme.px(8)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                text: result.modelData.name
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSize
                color: Theme.textColor
            }

            HoverHandler {
                id: rowHover
                onHoveredChanged: if (hovered && !sessionMenu.pointerStill) sessionMenu.selected = result.index
            }
            TapHandler { onTapped: sessionMenu.launch(result.modelData) }
        }
    }

    // Session buttons
    Repeater {
        model: sessionMenu.actionRows

        Row {
            id: actionRow
            required property var modelData
            visible: sessionMenu.pending === null
            width: parent.width - parent.leftPadding - parent.rightPadding
            spacing: Theme.px(8)

            Repeater {
                model: actionRow.modelData

                MenuButton {
                    id: actionButton
                    required property var modelData
                    width: (actionRow.width - (actionRow.modelData.length - 1) * actionRow.spacing) / actionRow.modelData.length
                    icon: modelData.icon
                    text: modelData.label
                    centered: true
                    stacked: true
                    onClicked: {
                        if (modelData.confirm) {
                            // This button is about to hide; keep keyboard focus in the menu
                            const hadFocus = activeFocus
                            sessionMenu.pendingButton = actionButton
                            sessionMenu.pending = modelData
                            if (hadFocus)
                                cancelButton.forceActiveFocus()
                        } else {
                            sessionMenu.run(modelData)
                        }
                    }
                }
            }
        }
    }

    MenuHeading {
        visible: sessionMenu.pending !== null
        text: sessionMenu.pending ? sessionMenu.pending.label + "?" : ""
    }

    Row {
        visible: sessionMenu.pending !== null
        width: parent.width - parent.leftPadding - parent.rightPadding
        spacing: Theme.px(8)

        MenuButton {
            id: cancelButton
            width: (parent.width - parent.spacing) / 2
            text: "Cancel"
            centered: true
            onClicked: {
                // Return focus to the button that asked for confirmation
                const hadFocus = activeFocus
                sessionMenu.pending = null
                if (hadFocus)
                    sessionMenu.pendingButton.forceActiveFocus()
            }
        }

        MenuButton {
            width: (parent.width - parent.spacing) / 2
            icon: sessionMenu.pending?.icon ?? ""
            text: "Confirm"
            centered: true
            contentColor: Theme.bad
            onClicked: sessionMenu.run(sessionMenu.pending)
        }
    }
}
