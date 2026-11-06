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

        Rectangle {
            visible: Notifications.history.length > 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: clearLabel.implicitWidth + Theme.px(20)
            height: Theme.px(24)
            radius: height / 2
            color: clearHover.hovered ? Theme.highlight : Theme.surface

            Text {
                id: clearLabel
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Theme.textOffset
                text: "Clear all"
                font.pixelSize: Theme.fontSize - Theme.px(2)
                color: Theme.textColor
            }

            HoverHandler { id: clearHover }
            TapHandler { onTapped: Notifications.clearAll() }
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
