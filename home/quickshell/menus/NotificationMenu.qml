import QtQuick
import Quickshell
import qs

// Notification history with a do-not-disturb switch and "Clear all", opened
// from the bell indicator. Set `anchor.item` to the indicator.
DropdownMenu {
    implicitWidth: 380

    Item {
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: Math.max(heading.implicitHeight, dndSwitch.implicitHeight)

        MenuHeading {
            id: heading
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
        }

        Text {
            anchors.right: dndSwitch.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Theme.textOffset
            text: "Do not disturb"
            font.pixelSize: Theme.fontSize - 2
            color: Theme.dimTextColor
        }

        MenuSwitch {
            id: dndSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: Notifications.dnd
            onToggled: Notifications.dnd = !Notifications.dnd
        }
    }

    Text {
        visible: Notifications.history.length === 0
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
        text: "No notifications"
    }

    // Scrolls once the list is taller than this
    Flickable {
        id: list
        visible: Notifications.history.length > 0
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: Math.min(cards.implicitHeight, 420)
        contentHeight: cards.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: cards
            width: list.width
            spacing: 6

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

    // Full-width row so the button can be anchored to the right
    Item {
        visible: Notifications.history.length > 0
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: 24

        Rectangle {
            anchors.right: parent.right
            width: clearLabel.implicitWidth + 20
            height: parent.height
            radius: height / 2
            color: clearHover.hovered ? Theme.highlight : Theme.surface

            Text {
                id: clearLabel
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Theme.textOffset
                text: "Clear all"
                font.pixelSize: Theme.fontSize - 2
                color: Theme.textColor
            }

            HoverHandler { id: clearHover }
            TapHandler { onTapped: Notifications.clearAll() }
        }
    }
}
