pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The session's notification service. Every notification is kept in
// `history` until dismissed; new ones are also shown as popups unless
// do-not-disturb is on (critical ones always pop up).
Singleton {
    id: root

    property bool dnd: false

    // Notifications currently shown as popups, oldest first
    property list<var> popups: []

    // All notifications not yet dismissed, newest first
    readonly property var history: server.trackedNotifications.values.slice().reverse()

    function hidePopup(n) {
        popups = popups.filter(p => p !== n)
        // Transient notifications shouldn't stay around in the history
        if (n.transient)
            n.expire()
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss()
    }

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        // Bodies are shown as plain text, so don't invite markup
        bodyMarkupSupported: false
        // Keep the history across QML reloads
        keepOnReload: true

        onNotification: n => {
            n.tracked = true
            // Drop it from the popups however it closes (dismissed, expired,
            // or closed by the app)
            n.closed.connect(() => {
                root.popups = root.popups.filter(p => p !== n)
            })
            // Re-sent after a reload: already seen, so history only
            if (n.lastGeneration)
                return
            if (root.dnd && n.urgency !== NotificationUrgency.Critical)
                return
            root.popups = root.popups.concat([n])
        }
    }
}
