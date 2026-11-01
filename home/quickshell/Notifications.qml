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

    // Arrival time of each tracked notification (ms since the epoch) keyed
    // by id, since the server doesn't record one. Kept across reloads, like
    // the notifications; as JSON, because a JS object can't cross engines.
    PersistentProperties {
        id: persist
        reloadableId: "notifications"
        property string arrived: "{}"
    }
    readonly property var arrived: JSON.parse(persist.arrived)

    // Updated every half minute so relative times stay current
    property real now: Date.now()
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    // How long ago notification `n` arrived, e.g. "now", "5 min ago", "3 h ago"
    function age(n) {
        const t = arrived[n.id]
        if (t === undefined)
            return ""
        const minutes = Math.floor((now - t) / 60000)
        if (minutes < 1)
            return "now"
        if (minutes < 60)
            return minutes + " min ago"
        const hours = Math.floor(minutes / 60)
        if (hours < 24)
            return hours + " h ago"
        const days = Math.floor(hours / 24)
        return days === 1 ? "yesterday" : days + " days ago"
    }

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
                const rest = Object.assign({}, root.arrived)
                delete rest[n.id]
                persist.arrived = JSON.stringify(rest)
            })
            // Re-sent after a reload: already seen, so history only
            if (n.lastGeneration)
                return
            persist.arrived = JSON.stringify(Object.assign({}, root.arrived, { [n.id]: Date.now() }))
            root.now = Date.now()
            if (root.dnd && n.urgency !== NotificationUrgency.Critical)
                return
            root.popups = root.popups.concat([n])
        }
    }
}
