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

    implicitHeight: content.implicitHeight + Theme.px(24)
    radius: Theme.px(12)
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
        x: Theme.px(12)
        y: Theme.px(12)
        width: parent.width - Theme.px(24)
        spacing: Theme.px(4)

        // Header: icon, app name, close button
        Item {
            width: parent.width
            height: Theme.px(20)

            IconImage {
                id: appIcon
                readonly property string icon: card.notification.appIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: Theme.px(16)
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
                width: Theme.px(16)
                horizontalAlignment: Text.AlignHCenter
                text: "\uf0f3" // bell
                font.family: Theme.iconFont
                font.weight: Font.Black
                font.pixelSize: Theme.iconSize
                color: Theme.dimTextColor
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.px(24)
                anchors.right: age.left
                anchors.rightMargin: Theme.px(8)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                elide: Text.ElideRight
                text: card.notification.appName
                textFormat: Text.PlainText
                font.pixelSize: Theme.fontSize - Theme.px(2)
                color: Theme.dimTextColor
            }

            // How long ago it arrived
            Text {
                id: age
                anchors.right: closeButton.left
                anchors.rightMargin: Theme.px(8)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.textOffset
                text: Notifications.age(card.notification)
                font.pixelSize: Theme.fontSize - Theme.px(2)
                color: Theme.dimTextColor
            }

            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.px(20)
                height: Theme.px(20)
                radius: width / 2
                color: closeHover.hovered ? Theme.highlight : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d" // xmark
                    font.family: Theme.iconFont
                    font.weight: Font.Black
                    font.pixelSize: Theme.iconSize - Theme.px(2)
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
            font.pixelSize: Theme.fontSize - Theme.px(1)
            color: Theme.textColor
        }

        // A profile picture stays small; a wide image (a screenshot
        // thumbnail) may take the card's width. Sized to the scaled image
        // itself so it sits at the left.
        Image {
            id: image
            readonly property bool wide: implicitWidth > implicitHeight * 1.5
            readonly property int maxWidth: wide ? parent.width : Theme.px(64)
            readonly property int maxHeight: wide ? Theme.px(120) : Theme.px(64)
            readonly property real scale: implicitWidth > 0 && implicitHeight > 0
                ? Math.min(1, maxWidth / implicitWidth, maxHeight / implicitHeight) : 1
            visible: card.notification.image !== "" && status === Image.Ready
            // An image-path hint with an absolute path arrives as
            // image://icon//path, which the icon provider can't load
            source: {
                const img = card.notification.image
                const prefix = "image://icon/"
                return img.startsWith(prefix + "/") ? "file://" + img.slice(prefix.length) : img
            }
            width: Math.round(implicitWidth * scale)
            height: Math.round(implicitHeight * scale)
            sourceSize.height: Theme.px(240)
        }

        Flow {
            width: parent.width
            visible: card.buttons.length > 0
            spacing: Theme.px(6)
            topPadding: Theme.px(4)

            Repeater {
                model: card.buttons

                Rectangle {
                    id: actionButton
                    required property var modelData
                    width: actionLabel.implicitWidth + 20
                    height: Theme.px(24)
                    radius: height / 2
                    color: actionHover.hovered ? Qt.lighter(card.buttonColor, 1.3) : card.buttonColor

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: Theme.textOffset
                        text: actionButton.modelData.text
                        textFormat: Text.PlainText
                        font.pixelSize: Theme.fontSize - Theme.px(2)
                        color: Theme.textColor
                    }

                    HoverHandler { id: actionHover }
                    TapHandler { onTapped: actionButton.modelData.invoke() }
                }
            }
        }
    }
}
