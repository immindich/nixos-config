import QtQuick
import QtQuick.Controls
import qs

// Month calendar, opened from the clock. Set `anchor.item` to the clock and
// `today` to its date. Opens on the current month; the arrows step through
// months and clicking the month name jumps back to today.
DropdownMenu {
    id: calendar

    property date today: new Date()
    // First day of the month on display
    property date shown: new Date()

    implicitWidth: 280

    function reset() {
        shown = new Date(today.getFullYear(), today.getMonth(), 1)
    }

    function step(months) {
        shown = new Date(shown.getFullYear(), shown.getMonth() + months, 1)
    }

    onVisibleChanged: {
        if (visible)
            reset()
    }
    Component.onCompleted: reset()

    // Small round button with a Font Awesome glyph, like the audio mute button
    component NavButton: Rectangle {
        id: button
        property alias icon: glyph.text
        signal clicked()

        width: 28
        height: 22
        radius: height / 2
        color: hover.hovered ? Theme.highlight : Theme.surface

        Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

        Text {
            id: glyph
            anchors.centerIn: parent
            font.family: Theme.iconFont
            font.weight: Font.Black
            font.pixelSize: Theme.iconSize - 2
            color: Theme.textColor
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: button.clicked() }
    }

    // Month name with previous/next buttons
    Item {
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: Math.max(heading.implicitHeight, 22)

        MenuHeading {
            id: heading
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(calendar.shown, "MMMM yyyy")

            TapHandler { onTapped: calendar.reset() }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            NavButton { icon: "\uf053"; onClicked: calendar.step(-1) } // chevron-left
            NavButton { icon: "\uf054"; onClicked: calendar.step(1) }  // chevron-right
        }
    }

    // These two controls size their delegates to fill their own width and
    // height (seven columns, and six rows for the grid), so they need
    // explicit heights rather than taking them from the delegates
    DayOfWeekRow {
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: 20
        spacing: 0
        locale: grid.locale

        delegate: Text {
            required property string shortName
            text: shortName
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Theme.fontSize - 2
            color: Theme.dimTextColor
        }
    }

    // Days of the month, with the surrounding months' days dimmed and today
    // in an accent circle
    MonthGrid {
        id: grid
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: 6 * 28
        spacing: 0
        month: calendar.shown.getMonth()
        year: calendar.shown.getFullYear()
        locale: Qt.locale()

        delegate: Item {
            id: day
            required property var model
            readonly property bool isToday: model.day === calendar.today.getDate()
                && model.month === calendar.today.getMonth()
                && model.year === calendar.today.getFullYear()

            Rectangle {
                anchors.centerIn: parent
                width: 26
                height: 26
                radius: height / 2
                color: Theme.accent
                visible: day.isToday
            }

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Theme.textOffset
                text: day.model.day
                font.pixelSize: Theme.fontSize - 1
                color: day.isToday ? Theme.background
                    : day.model.month === grid.month ? Theme.textColor : Theme.dimTextColor
            }
        }
    }
}
