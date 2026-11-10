import QtQuick
import qs

// Small rounded text button for menus ("Clear all", "Connect"). While not
// `active` its label is dimmed and it ignores clicks.
Rectangle {
    id: button

    property alias text: label.text
    property bool active: true
    // Room either side of the label
    property int horizontalPadding: Theme.px(10)
    signal clicked()

    width: label.implicitWidth + 2 * horizontalPadding
    height: Theme.px(24)
    radius: height / 2
    color: hover.hovered && active ? Theme.highlight : Theme.surface

    Text {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Theme.textOffset
        font.pixelSize: Theme.fontSize - Theme.px(2)
        color: button.active ? Theme.textColor : Theme.dimTextColor
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: if (button.active) button.clicked() }
}
