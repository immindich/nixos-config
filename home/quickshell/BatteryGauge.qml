import QtQuick

// Battery outline filled in proportion to `level` (0-1), with a bolt over it
// while `charging`
Item {
    id: gauge
    property real level: 0
    property bool charging: false
    property color color: Theme.textColor

    readonly property real lineWidth: 1.5
    // Terminal nub on the right
    readonly property real nubWidth: 2
    readonly property real nubHeight: 5

    width: 22
    height: 11

    Rectangle {
        id: body
        width: parent.width - gauge.nubWidth
        height: parent.height
        radius: 3
        color: "transparent"
        border.color: gauge.color
        border.width: gauge.lineWidth

        // Charge, inset from the outline by a gap
        Rectangle {
            readonly property real inset: gauge.lineWidth + 1
            x: inset
            y: inset
            width: (body.width - 2 * inset) * Math.max(0, Math.min(1, gauge.level))
            height: body.height - 2 * inset
            radius: 1
            color: gauge.color
        }
    }

    Rectangle {
        anchors.left: body.right
        anchors.verticalCenter: parent.verticalCenter
        width: gauge.nubWidth
        height: gauge.nubHeight
        radius: 1
        color: gauge.color
    }

    // Outlined in the bubble color so it shows over both the fill and the
    // empty part
    Text {
        anchors.centerIn: body
        visible: gauge.charging
        text: "\uf0e7" // bolt
        font.family: Theme.iconFont
        font.weight: Font.Black
        font.pixelSize: 9
        color: gauge.color
        style: Text.Outline
        styleColor: Theme.background
    }
}
