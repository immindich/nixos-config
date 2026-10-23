import QtQuick

// Four bars, lit according to `strength` (0-1). While `connecting`, they
// light up one after another instead, to show a connection being made.
Row {
    id: bars
    property real strength: 0
    property bool connecting: false
    property color color: Theme.textColor
    property color dimColor: Theme.surface

    // Bar lit while connecting
    property int step: 0
    readonly property int lit: connecting ? step + 1 : Math.max(1, Math.ceil(strength * 4))

    spacing: 2
    height: 12

    onConnectingChanged: step = 0

    Timer {
        running: bars.connecting
        repeat: true
        interval: 250
        onTriggered: bars.step = (bars.step + 1) % 4
    }

    Repeater {
        model: 4

        Rectangle {
            required property int index
            anchors.bottom: parent.bottom
            width: 3
            height: 3 + index * 3
            radius: 1
            color: index < bars.lit ? bars.color : bars.dimColor
        }
    }
}
