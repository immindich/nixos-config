import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// Notification popups, stacked down from the top right under the bar on the
// focused monitor. Each hides after its timeout (5s by default; critical ones
// stay until dismissed); hovering pauses the timer. Hidden popups stay in
// the history menu.
PanelWindow {
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.barMargin
        right: Theme.barMargin
    }
    // Sit below the bar's reserved space without reserving any itself
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    // Only exists while there's something to show, so it never blocks clicks
    visible: Notifications.popups.length > 0
    implicitWidth: 360
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"

    Column {
        id: stack
        width: parent.width
        spacing: 6

        Repeater {
            // ScriptModel keeps existing cards (and their timers) when
            // popups are added or removed
            model: ScriptModel { values: Notifications.popups }

            NotificationCard {
                id: popup
                required property var modelData
                notification: modelData
                width: stack.width

                HoverHandler { id: hover }

                Timer {
                    running: popup.notification.urgency !== NotificationUrgency.Critical && !hover.hovered
                    // expireTimeout is in milliseconds (the docs say seconds,
                    // but it arrives as sent, e.g. 8000 for 8s)
                    interval: popup.notification.expireTimeout > 0 ? popup.notification.expireTimeout : 5000
                    onTriggered: Notifications.hidePopup(popup.notification)
                }
            }
        }
    }
}
