import QtQuick
import qs

// Text field with a magnifying glass and a placeholder, for menus that filter
// a list as you type. Focusing it focuses the text input. Up and Down are
// reported for moving through the list, Enter as `accepted()`.
FocusScope {
    id: field

    property alias text: input.text
    property alias placeholder: placeholderText.text
    signal accepted()
    signal upPressed()
    signal downPressed()

    width: parent.width - parent.leftPadding - parent.rightPadding
    height: Theme.px(30)

    Rectangle {
        anchors.fill: parent
        radius: Theme.px(8)
        color: Theme.surface
        border.width: input.activeFocus ? 1 : 0
        border.color: Theme.accent

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.px(10)
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf002" // magnifying-glass
            font.family: Theme.iconFont
            font.weight: Font.Black
            font.pixelSize: Theme.iconSize
            color: Theme.dimTextColor
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: Theme.px(32)
            anchors.rightMargin: Theme.px(10)
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            focus: true
            font.pixelSize: Theme.fontSize
            color: Theme.textColor
            selectionColor: Theme.accent

            onAccepted: field.accepted()
            Keys.onUpPressed: field.upPressed()
            Keys.onDownPressed: field.downPressed()

            Text {
                id: placeholderText
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                font.pixelSize: Theme.fontSize
                color: Theme.dimTextColor
            }
        }
    }
}
