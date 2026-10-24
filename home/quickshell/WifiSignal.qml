import QtQuick
import QtQuick.Shapes

// Wi-Fi fan: a dot with three arcs above it, lit from the dot outward
// according to `strength` (0-1). While `connecting`, they light up one after
// another instead, to show a connection being made.
Item {
    id: signal
    property real strength: 0
    property bool connecting: false
    property color color: Theme.textColor
    property color dimColor: Theme.surface

    // Element lit while connecting; 0 is the dot
    property int step: 0
    readonly property int lit: connecting ? step + 1 : Math.max(1, Math.ceil(strength * 4))

    // Distance between arcs, center to center
    readonly property real arcStep: 3
    readonly property real lineWidth: 1.75
    readonly property real dotRadius: 1.5
    // Center of the fan, at the dot
    readonly property real centerX: width / 2
    readonly property real centerY: height - dotRadius

    width: 16
    height: 13

    onConnectingChanged: step = 0

    Timer {
        running: signal.connecting
        repeat: true
        interval: 250
        onTriggered: signal.step = (signal.step + 1) % 4
    }

    Rectangle {
        x: signal.centerX - signal.dotRadius
        y: signal.centerY - signal.dotRadius
        width: 2 * signal.dotRadius
        height: width
        radius: signal.dotRadius
        color: signal.lit > 0 ? signal.color : signal.dimColor
    }

    Repeater {
        model: 3

        Shape {
            id: arc
            required property int index
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: arc.index + 1 < signal.lit ? signal.color : signal.dimColor
                strokeWidth: signal.lineWidth
                capStyle: ShapePath.RoundCap

                // A quarter circle opening upward
                PathAngleArc {
                    centerX: signal.centerX
                    centerY: signal.centerY
                    radiusX: (arc.index + 1) * signal.arcStep + 1
                    radiusY: radiusX
                    startAngle: -135
                    sweepAngle: 90
                }
            }
        }
    }
}
