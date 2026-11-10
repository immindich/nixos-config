import QtQuick
import qs

// "Label ........ value" row for a DropdownMenu
Item {
    property alias label: labelText.text
    property alias value: valueText.text

    width: parent.width - parent.leftPadding - parent.rightPadding
    implicitHeight: Math.max(labelText.implicitHeight, valueText.implicitHeight)

    // Plain text, like every label that may show other programs' strings
    Text {
        id: labelText
        textFormat: Text.PlainText
        anchors.left: parent.left
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
    }

    Text {
        id: valueText
        textFormat: Text.PlainText
        anchors.right: parent.right
        font.pixelSize: Theme.fontSize
        color: Theme.textColor
    }
}
