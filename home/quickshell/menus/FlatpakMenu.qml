import QtQuick
import qs

// Pending Flatpak updates with an "Update all" button, opened from the
// updates indicator. Set `anchor.item` to the indicator; the list comes from
// the FlatpakUpdates singleton, which is checked again whenever this opens.
DropdownMenu {
    id: flatpakMenu

    onVisibleChanged: if (visible) FlatpakUpdates.refresh()

    // Pill button like the notification menu's "Clear all"
    component PillButton: Rectangle {
        id: button
        property alias text: buttonLabel.text
        property bool active: true
        signal clicked()

        width: buttonLabel.implicitWidth + 20
        height: 24
        radius: height / 2
        color: buttonHover.hovered && active ? Theme.highlight : Theme.surface

        Text {
            id: buttonLabel
            anchors.centerIn: parent
            anchors.verticalCenterOffset: Theme.textOffset
            font.pixelSize: Theme.fontSize - 2
            color: button.active ? Theme.textColor : Theme.dimTextColor
        }

        HoverHandler { id: buttonHover }
        TapHandler { onTapped: if (button.active) button.clicked() }
    }

    // Heading, with when the list was last checked on the right
    Item {
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: heading.implicitHeight

        MenuHeading { id: heading; text: "Flatpak updates" }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: FlatpakUpdates.updating ? "Updating…"
                : isNaN(FlatpakUpdates.checked.getTime()) ? ""
                : "Checked " + Qt.formatTime(FlatpakUpdates.checked, "h:mm AP")
            font.pixelSize: Theme.fontSize - 2
            color: Theme.dimTextColor
        }
    }

    Text {
        visible: FlatpakUpdates.updates.length === 0
        text: FlatpakUpdates.checking ? "Checking…" : "Everything is up to date"
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
    }

    // Name on the left, new version on the right. Apps that publish no
    // version show nothing; runtimes show their branch, e.g. "24.08".
    Repeater {
        model: FlatpakUpdates.updates

        Item {
            required property var modelData
            width: parent.width - parent.leftPadding - parent.rightPadding
            implicitHeight: nameText.implicitHeight

            Text {
                id: nameText
                anchors.left: parent.left
                anchors.right: versionText.left
                anchors.rightMargin: 8
                text: parent.modelData.name
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSize
                color: Theme.textColor
            }

            Text {
                id: versionText
                anchors.right: parent.right
                text: parent.modelData.version
                    || (parent.modelData.branch !== "stable" ? parent.modelData.branch : "")
                textFormat: Text.PlainText
                font.pixelSize: Theme.fontSize
                color: Theme.dimTextColor
            }
        }
    }

    Text {
        visible: FlatpakUpdates.error !== ""
        width: parent.width - parent.leftPadding - parent.rightPadding
        text: FlatpakUpdates.error
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSize - 2
        color: Theme.bad
    }

    // Full-width row so the buttons can be anchored to the right
    Item {
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: 24

        Row {
            anchors.right: parent.right
            spacing: 6

            PillButton {
                text: "Check now"
                active: !FlatpakUpdates.checking && !FlatpakUpdates.updating
                onClicked: FlatpakUpdates.refresh()
            }
            PillButton {
                visible: FlatpakUpdates.updates.length > 0
                text: "Update all"
                active: !FlatpakUpdates.updating
                onClicked: FlatpakUpdates.updateAll()
            }
        }
    }
}
