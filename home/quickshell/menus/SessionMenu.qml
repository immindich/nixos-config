import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import qs

// Start menu, opened from the NixOS button: an application search field
// (type, pick with Up/Down, launch with Enter) above a row of lock, sleep,
// power and exit Hyprland buttons. All but lock open a second step with
// the choices behind them (sleep or hibernate, restart or shut down) or a
// confirmation. Tab cycles between the search field and the buttons.
// Set `anchor.item` to the button.
KeyboardMenu {
    id: sessionMenu
    menuWidth: Theme.px(300)

    // Action whose choices are showing, or null while showing the buttons
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

    // An action with `choices` shows `prompt` and a button per choice
    // instead of running a command; `danger` draws a choice in Theme.bad
    readonly property var actions: [
        { icon: "\uf023", label: "Lock", command: "loginctl lock-session" }, // lock
        { icon: "\uf186", label: "Sleep", prompt: "Sleep or hibernate?", choices: [ // moon
            { label: "Sleep", command: "systemctl suspend" },
            { label: "Hibernate", command: "systemctl hibernate" },
        ] },
        { icon: "\uf011", label: "Power", prompt: "Restart or shut down?", choices: [ // power-off
            { label: "Restart", command: "systemctl reboot", danger: true },
            { label: "Shut down", command: "systemctl poweroff", danger: true },
        ] },
        { icon: "\uf2f5", label: "Exit Hyprland", prompt: "Exit Hyprland?", choices: [ // right-from-bracket
            // Same as the SUPER+M bind
            { label: "Exit", danger: true,
              command: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'" },
        ] },
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

    onResultsChanged: selected = 0

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

    // Rounded button with an optional Font Awesome icon before its label;
    // content is left-aligned unless `centered`. Reachable with Tab and
    // pressed with Enter or Space.
    component MenuButton: Rectangle {
        id: button
        property alias icon: iconText.text
        property alias text: labelText.text
        property color contentColor: Theme.textColor
        property bool centered: false
        signal clicked()

        implicitHeight: Theme.px(28)
        radius: height / 2
        color: hover.hovered ? Theme.highlight : Theme.surface
        border.width: activeFocus ? 1 : 0
        border.color: Theme.accent

        activeFocusOnTab: true
        Keys.onReturnPressed: button.clicked()
        Keys.onEnterPressed: button.clicked()
        Keys.onSpacePressed: button.clicked()

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: button.centered ? parent.horizontalCenter : undefined
            anchors.left: button.centered ? undefined : parent.left
            anchors.leftMargin: Theme.px(12)
            spacing: Theme.px(10)

            Text {
                id: iconText
                visible: text !== ""
                width: Theme.px(16)
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.iconFont
                font.weight: Font.Black
                font.pixelSize: Theme.iconSize
                color: button.contentColor
            }

            Text {
                id: labelText
                visible: text !== ""
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                font.pixelSize: Theme.fontSize
                color: button.contentColor
            }
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: button.clicked() }
    }

    // Search field
    Rectangle {
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: Theme.px(30)
        radius: Theme.px(8)
        color: Theme.surface
        border.width: searchInput.activeFocus ? 1 : 0
        border.color: Theme.accent

        Text {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: Theme.px(10)
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf002"
            font.family: Theme.iconFont
            font.weight: Font.Black
            font.pixelSize: Theme.iconSize
            color: Theme.dimTextColor
        }

        TextInput {
            id: searchInput
            anchors.fill: parent
            anchors.leftMargin: Theme.px(32)
            anchors.rightMargin: Theme.px(10)
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            font.pixelSize: Theme.fontSize
            color: Theme.textColor
            selectionColor: Theme.accent
            activeFocusOnTab: true

            onAccepted: {
                const entry = sessionMenu.results[sessionMenu.selected]
                if (entry)
                    sessionMenu.launch(entry)
            }
            Keys.onUpPressed: sessionMenu.selected = Math.max(sessionMenu.selected - 1, 0)
            Keys.onDownPressed: sessionMenu.selected = Math.min(sessionMenu.selected + 1, sessionMenu.results.length - 1)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: searchInput.text === ""
                text: "Search applications"
                font.pixelSize: Theme.fontSize
                color: Theme.dimTextColor
            }
        }
    }

    // Search results
    Repeater {
        model: sessionMenu.results

        Rectangle {
            id: result
            required property var modelData
            required property int index
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

            HoverHandler { onHoveredChanged: if (hovered) sessionMenu.selected = result.index }
            TapHandler { onTapped: sessionMenu.launch(result.modelData) }
        }
    }

    // Session buttons
    Row {
        visible: sessionMenu.pending === null
        width: parent.width - parent.leftPadding - parent.rightPadding
        spacing: Theme.px(8)

        Repeater {
            model: sessionMenu.actions

            MenuButton {
                id: actionButton
                required property var modelData
                width: (parent.width - 3 * parent.spacing) / 4
                icon: modelData.icon
                centered: true
                onClicked: {
                    if (modelData.choices) {
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

    MenuHeading {
        visible: sessionMenu.pending !== null
        text: sessionMenu.pending?.prompt ?? ""
    }

    Row {
        visible: sessionMenu.pending !== null
        width: parent.width - parent.leftPadding - parent.rightPadding
        spacing: Theme.px(8)

        // Cancel plus one button per choice, all the same width
        readonly property real buttonWidth: {
            const count = 1 + (sessionMenu.pending?.choices.length ?? 1)
            return (width - (count - 1) * spacing) / count
        }

        MenuButton {
            id: cancelButton
            width: parent.buttonWidth
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

        Repeater {
            model: sessionMenu.pending?.choices ?? []

            MenuButton {
                required property var modelData
                width: parent.buttonWidth
                // No icon: three labelled buttons only just fit the menu
                text: modelData.label
                centered: true
                contentColor: modelData.danger ? Theme.bad : Theme.textColor
                onClicked: sessionMenu.run(modelData)
            }
        }
    }
}
