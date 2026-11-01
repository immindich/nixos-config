import QtQuick
import Quickshell

// Small label that appears below `anchor.item` (above it with the bar at
// the bottom) while `shown`, after a short delay. Ignores the pointer, so
// it never gets in the way of the bar.
PopupWindow {
    id: tooltip
    property alias text: label.text
    property bool shown: false

    anchor.rect.x: anchor.item ? (anchor.item.width - width) / 2 : 0
    anchor.rect.y: anchor.item ? (Theme.barOnBottom ? -Theme.px(8) : anchor.item.height + Theme.px(8)) : 0
    anchor.rect.width: Theme.px(1)
    anchor.rect.height: Theme.px(1)
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: (Theme.barOnBottom ? Edges.Top : Edges.Bottom) | Edges.Right

    implicitWidth: label.implicitWidth + Theme.px(16)
    implicitHeight: label.implicitHeight + Theme.px(8)
    color: "transparent"
    mask: Region {}

    visible: false
    onShownChanged: {
        if (shown)
            delay.restart()
        else {
            delay.stop()
            visible = false
        }
    }
    Timer {
        id: delay
        interval: 500
        onTriggered: tooltip.visible = true
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.menuColor
        border.width: Theme.menuBorder
        border.color: Theme.borderColor

        Text {
            id: label
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSize
            color: Theme.textColor
        }
    }
}
