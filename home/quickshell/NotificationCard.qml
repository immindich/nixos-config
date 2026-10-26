import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

// One notification: app icon and name, summary, body, optional image and
// action buttons. Used for popups and in the history menu. Clicking runs the
// notification's default action (if any); middle click or ✕ dismisses it.
Rectangle {
    id: card

    required property var notification
    // Background of action buttons; set lighter when the card itself is grey
    property color buttonColor: Theme.surface
    readonly property var defaultAction: notification.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: notification.actions.filter(a => a.identifier !== "default")

    implicitHeight: content.implicitHeight + 24
    radius: 12
    color: Theme.background
    border.width: notification.urgency === NotificationUrgency.Critical ? 1 : 0
    border.color: Theme.bad

    // Left click: default action; middle click: dismiss
    TapHandler {
        acceptedButtons: Qt.LeftButton
        enabled: card.defaultAction !== null
        onTapped: card.defaultAction.invoke()
    }
    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: card.notification.dismiss()
    }

    Column {
        id: content
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 4

        // Header: icon, app name, close button
        Item {
            width: parent.width
            height: 20

            IconImage {
                id: appIcon
                readonly property string icon: card.notification.appIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                // URLs as-is, absolute paths as file URLs (a bare path would
                // resolve against this file's qrc: location), otherwise look
                // up the icon name
                source: icon.includes("://") ? icon
                    : icon.startsWith("/") ? "file://" + icon
                    : icon !== "" ? Quickshell.iconPath(icon, true) : ""
                visible: source != ""
            }

            Text {
                id: fallbackIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: !appIcon.visible
                width: 16
                horizontalAlignment: Text.AlignHCenter
                text: "\uf0f3" // bell
                font.family: Theme.iconFont
                font.weight: Font.Black
                font.pixelSize: Theme.iconSize
                color: Theme.dimTextColor
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: closeButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                elide: Text.ElideRight
                text: card.notification.appName
                textFormat: Text.PlainText
                font.pixelSize: Theme.fontSize - 2
                color: Theme.dimTextColor
            }

            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                radius: width / 2
                color: closeHover.hovered ? Theme.highlight : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d" // xmark
                    font.family: Theme.iconFont
                    font.weight: Font.Black
                    font.pixelSize: Theme.iconSize - 2
                    color: Theme.dimTextColor
                }

                HoverHandler { id: closeHover }
                TapHandler { onTapped: card.notification.dismiss() }
            }
        }

        Text {
            width: parent.width
            visible: text !== ""
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: card.notification.summary
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.textColor
        }

        Text {
            width: parent.width
            visible: text !== ""
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: card.notification.body
            font.pixelSize: Theme.fontSize - 1
            color: Theme.textColor
        }

        // e.g. a profile picture
        Image {
            visible: card.notification.image !== "" && status === Image.Ready
            source: card.notification.image
            fillMode: Image.PreserveAspectFit
            width: Math.min(implicitWidth, 64)
            height: Math.min(implicitHeight, 64)
            sourceSize.height: 128
        }

        Flow {
            width: parent.width
            visible: card.buttons.length > 0
            spacing: 6
            topPadding: 4

            Repeater {
                model: card.buttons

                Rectangle {
                    id: actionButton
                    required property var modelData
                    width: actionLabel.implicitWidth + 20
                    height: 24
                    radius: height / 2
                    color: actionHover.hovered ? Qt.lighter(card.buttonColor, 1.3) : card.buttonColor

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: Theme.textOffset
                        text: actionButton.modelData.text
                        textFormat: Text.PlainText
                        font.pixelSize: Theme.fontSize - 2
                        color: Theme.textColor
                    }

                    HoverHandler { id: actionHover }
                    TapHandler { onTapped: actionButton.modelData.invoke() }
                }
            }
        }
    }
}
