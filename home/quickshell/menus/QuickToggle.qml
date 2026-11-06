import QtQuick
import qs

// Control center tile: icon, label and a one-line status, filled while
// `checked`. Clicking the tile emits `toggled()`; the chevron on its right
// emits `expandToggled()`, for showing the setting's details below the
// tiles. Like MenuSwitch, it leaves updating `checked` and `expanded` to the
// owner.
Rectangle {
    id: tile

    property alias icon: glyph.text
    property alias iconFont: glyph.font.family // Theme.brandIconFont for brand glyphs
    property alias label: labelText.text
    property alias status: statusText.text
    property bool checked: false
    property bool expanded: false
    signal toggled()
    signal expandToggled()

    readonly property color fgColor: checked ? Theme.controlText : Theme.textColor

    implicitHeight: Theme.px(48)
    radius: Theme.px(12)
    color: checked ? Theme.controlFill : tileHover.hovered ? Theme.highlight : Theme.surface

    Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

    HoverHandler { id: tileHover }

    Text {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: Theme.px(10)
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.px(16)
        horizontalAlignment: Text.AlignHCenter
        font.family: Theme.iconFont
        font.weight: Font.Black
        font.pixelSize: Theme.iconSize + Theme.px(2)
        color: tile.fgColor
    }

    Column {
        anchors.left: glyph.right
        anchors.leftMargin: Theme.px(8)
        anchors.right: chevron.left
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: labelText
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: tile.fgColor
        }

        Text {
            id: statusText
            width: parent.width
            visible: text !== ""
            elide: Text.ElideRight
            // May be a device name
            textFormat: Text.PlainText
            font.pixelSize: Theme.fontSize - Theme.px(2)
            color: tile.fgColor
            opacity: 0.8
        }
    }

    // One handler for the whole tile, so a click on the chevron doesn't also
    // toggle
    TapHandler {
        onTapped: eventPoint => {
            if (chevron.contains(chevron.mapFromItem(tile, eventPoint.position)))
                tile.expandToggled()
            else
                tile.toggled()
        }
    }

    // Expand button
    Rectangle {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: Theme.px(4)
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.px(24)
        height: width
        radius: width / 2
        color: chevronHover.hovered ? Qt.rgba(tile.fgColor.r, tile.fgColor.g, tile.fgColor.b, 0.15) : "transparent"

        Text {
            anchors.centerIn: parent
            text: tile.expanded ? "\uf077" : "\uf078" // chevron-up : chevron-down
            font.family: Theme.iconFont
            font.weight: Font.Black
            font.pixelSize: Theme.iconSize - Theme.px(2)
            color: tile.fgColor
        }

        HoverHandler { id: chevronHover }
    }
}
