import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

// ALT+Tab window switcher: every window, most recently focused first, in a
// box in the middle of the focused screen. Opens with the previous window
// selected; Tab and SHIFT+Tab move the selection while ALT is held, and
// letting go of ALT focuses it. Escape cancels. A click on a row focuses
// that window.
//
// The keys are Hyprland binds (home/hyprland.nix) that trigger the global
// shortcuts below, and Hyprland enters and leaves the alttab submap itself,
// so this window never takes the keyboard.
PanelWindow {
    id: switcher

    // Window addresses, most recently focused first. Hyprland's own focus
    // history (lastIpcObject.focusHistoryID) is only fetched now and then,
    // so it only orders windows that haven't been focused since the shell
    // started.
    property var history: []
    // Snapshot of the windows taken when the switcher opens
    property var entries: []
    property int selected: 0
    property bool shown: false

    function rank(toplevel) {
        const i = history.indexOf(toplevel.address)
        return i >= 0 ? i : history.length + (toplevel.lastIpcObject?.focusHistoryID ?? 1000)
    }

    function open() {
        if (shown) {
            step(1)
            return
        }
        // A focus change that hasn't settled yet is final by now
        if (focusSettle.running) {
            focusSettle.stop()
            recordFocus()
        }
        const windows = Hyprland.toplevels.values.slice()
        if (windows.length === 0)
            return
        windows.sort((a, b) => rank(a) - rank(b))
        entries = windows
        selected = windows.length > 1 ? 1 : 0
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        shown = true
    }

    function step(delta) {
        if (shown && entries.length > 0)
            selected = (selected + delta + entries.length) % entries.length
    }

    function commit() {
        if (!shown)
            return
        shown = false
        const address = entries[selected]?.address ?? ""
        entries = []
        // Only an address Hyprland gave us goes into the dispatch
        if (/^[0-9a-f]+$/.test(address))
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${address}" })`)
    }

    function cancel() {
        shown = false
        entries = []
    }

    // Move the focused window to the front of the history
    function recordFocus() {
        const address = Hyprland.activeToplevel?.address
        if (address)
            history = [address].concat(history.filter(a => a !== address))
    }

    // Focusing a window on another workspace first activates that
    // workspace's last window for a moment; only count a window once it has
    // kept the focus briefly
    Timer {
        id: focusSettle
        interval: 150
        onTriggered: switcher.recordFocus()
    }
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() { focusSettle.restart() }
    }

    GlobalShortcut { appid: "quickshell"; name: "alttab-open"; onPressed: switcher.open() }
    GlobalShortcut { appid: "quickshell"; name: "alttab-next"; onPressed: switcher.step(1) }
    GlobalShortcut { appid: "quickshell"; name: "alttab-prev"; onPressed: switcher.step(-1) }
    // Sent from a release bind, which reaches the shell as a release
    GlobalShortcut {
        appid: "quickshell"
        name: "alttab-commit"
        onPressed: switcher.commit()
        onReleased: switcher.commit()
    }
    GlobalShortcut { appid: "quickshell"; name: "alttab-cancel"; onPressed: switcher.cancel() }

    visible: shown
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-switcher"
    implicitWidth: 480
    implicitHeight: list.implicitHeight + 16
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.background

        ColumnLayout {
            id: list
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            Repeater {
                model: switcher.entries

                // App icon, title and workspace; the selected row is
                // highlighted
                Rectangle {
                    id: entry
                    required property HyprlandToplevel modelData
                    required property int index
                    readonly property bool isSelected: index === switcher.selected
                    // The app id (window class) names the desktop entry,
                    // which names the icon
                    readonly property string appId: modelData.wayland?.appId ?? ""
                    readonly property var desktopEntry: {
                        // The lookup isn't reactive on its own; depend on the
                        // index so it runs again once the entries are scanned
                        DesktopEntries.applications.values
                        return appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
                    }

                    Layout.fillWidth: true
                    implicitHeight: Theme.bubbleHeight + 8
                    radius: height / 2
                    color: isSelected ? Theme.highlight : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        IconImage {
                            implicitSize: 20
                            source: Quickshell.iconPath(entry.desktopEntry?.icon ?? "", "application-x-executable")
                        }

                        Text {
                            Layout.fillWidth: true
                            text: entry.modelData.title
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pixelSize: Theme.fontSize
                            color: entry.isSelected ? Theme.accent : Theme.textColor
                        }

                        Text {
                            text: entry.modelData.workspace?.name ?? ""
                            textFormat: Text.PlainText
                            font.pixelSize: Theme.fontSize
                            color: Theme.dimTextColor
                        }
                    }

                    TapHandler {
                        onTapped: {
                            switcher.selected = entry.index
                            switcher.commit()
                            // ALT is still held, so Hyprland is still in the
                            // submap
                            Hyprland.dispatch('hl.dsp.submap("reset")')
                        }
                    }
                }
            }
        }
    }
}
