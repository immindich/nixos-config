import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// Notification popups, stacked down from the top right under the bar on the
// focused monitor. Each hides after its timeout (5s by default; critical ones
// stay until dismissed); hovering pauses the timer, and a two-finger swipe
// right hides one early. Hidden popups stay in the history menu.
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

                // Two-finger swipe right hides the popup, keeping it in the
                // history. Hyprland doesn't tell apps about natural scrolling,
                // so this follows the content: with natural scrolling on, that's
                // the way the fingers move.
                property real swipeOffset: 0
                // Movement of the latest event: a quick flick flies out early
                property real swipeSpeed: 0
                transform: Translate { x: popup.swipeOffset }
                opacity: 1 - Math.min(swipeOffset / width, 1)

                function swipe(event) {
                    if (flyOut.running)
                        return
                    if (event.phase === Qt.ScrollEnd) {
                        settle()
                        return
                    }
                    // Touchpads report pixels; wheels only angles (120 a notch)
                    const dx = event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.angleDelta.x / 4
                    snapBack.stop()
                    swipeSpeed = dx
                    swipeOffset = Math.max(0, swipeOffset + dx)
                    // A committed flick goes now: touchpads often send no
                    // scroll-end after one, and waiting for the timer stalls it
                    if (swipeSpeed >= 8 && swipeOffset > width / 6)
                        settle()
                    else
                        swipeIdle.restart()
                }

                // Past a sixth of the width, or still moving fast when the
                // fingers lift, it flies out; otherwise it springs back
                function settle() {
                    swipeIdle.stop()
                    if (swipeOffset > 0 && (swipeOffset > width / 6 || swipeSpeed >= 8))
                        flyOut.start()
                    else if (swipeOffset > 0)
                        snapBack.start()
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    orientation: Qt.Horizontal
                    onWheel: event => popup.swipe(event)
                }

                // Wheels and some touchpads never send a scroll-end event
                Timer {
                    id: swipeIdle
                    interval: 100
                    onTriggered: popup.settle()
                }

                NumberAnimation {
                    id: flyOut
                    target: popup
                    property: "swipeOffset"
                    to: popup.width
                    duration: Theme.animationDuration
                    easing.type: Easing.OutCubic
                    onFinished: Notifications.hidePopup(popup.notification)
                }

                NumberAnimation {
                    id: snapBack
                    target: popup
                    property: "swipeOffset"
                    to: 0
                    duration: Theme.animationDuration
                    easing.type: Easing.OutCubic
                }

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
