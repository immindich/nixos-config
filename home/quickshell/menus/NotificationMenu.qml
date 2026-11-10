import QtQuick
import Quickshell
import qs

// Notification history with "Clear all", opened from the bell indicator.
// Set `anchor.item` to the indicator. Do-not-disturb is in the control
// center.
DropdownMenu {
    menuWidth: Theme.px(380)

    // Heading with "Clear all" on the right
    Item {
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: Math.max(heading.implicitHeight, Theme.px(24))

        MenuHeading {
            id: heading
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
        }

        PillButton {
            visible: Notifications.history.length > 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Clear all"
            onClicked: Notifications.clearAll()
        }
    }

    // Scrolls once the list is taller than this
    Flickable {
        id: list
        visible: Notifications.history.length > 0
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: Math.min(cards.implicitHeight, Theme.px(420))
        contentHeight: cards.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: cards
            width: list.width
            spacing: Theme.px(6)

            Repeater {
                model: ScriptModel { values: Notifications.history }

                NotificationCard {
                    required property var modelData
                    notification: modelData
                    width: cards.width
                    // Set apart from the menu's own background
                    color: Theme.surface
                    buttonColor: Theme.highlight
                }
            }
        }
    }
}
