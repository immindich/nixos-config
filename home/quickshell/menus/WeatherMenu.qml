import QtQuick
import qs

// Current conditions, today's range and the next few hours, opened from the
// weather indicator. Set `anchor.item` to the indicator; the data comes from
// the Weather singleton.
DropdownMenu {
    id: weatherMenu

    component Icon: Text {
        font.family: Theme.iconFont
        font.weight: Font.Black
        color: Theme.textColor
    }

    MenuHeading { text: "Weather" }

    // Big icon and temperature, with the conditions beside them
    Row {
        spacing: 10

        Icon {
            text: Weather.icon
            font.pixelSize: Theme.fontSize * 2
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: Weather.temperature + "°"
                font.pixelSize: Theme.fontSize * 1.5
                color: Theme.textColor
            }
            Text {
                text: Weather.description
                font.pixelSize: Theme.fontSize
                color: Theme.dimTextColor
            }
        }
    }

    MenuInfoRow { label: "Feels like"; value: Weather.apparentTemperature + "°" }
    MenuInfoRow { label: "High / Low"; value: Weather.high + "° / " + Weather.low + "°" }
    MenuInfoRow { label: "Chance of rain"; value: Weather.precipitationChance + "%" }
    MenuInfoRow { label: "Humidity"; value: Weather.humidity + "%" }
    MenuInfoRow { label: "Wind"; value: Weather.windSpeed + " " + Weather.windSpeedUnit }

    // The next hours: time, icon and temperature in a column each
    Row {
        id: hourly
        width: parent.width - parent.leftPadding - parent.rightPadding

        Repeater {
            model: Weather.hours

            Column {
                required property var modelData
                width: hourly.width / Weather.hours.length
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.modelData.label
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.dimTextColor
                }
                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.iconFor(parent.modelData.code, parent.modelData.day)
                    font.pixelSize: Theme.iconSize
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.modelData.temperature + "°"
                    font.pixelSize: Theme.fontSize
                    color: Theme.textColor
                }
            }
        }
    }

    MenuInfoRow { label: "Updated"; value: Qt.formatTime(Weather.updated, "hh:mm") }
}
