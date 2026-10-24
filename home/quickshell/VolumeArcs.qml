import QtQuick
import QtQuick.Shapes

// Four sound-wave arcs to put after a speaker glyph, lit according to `level`
// (0-1). Any level above 0 lights at least one arc; 0 lights none.
Item {
    id: arcs
    property real level: 0
    property color color: Theme.textColor
    property color dimColor: Theme.surface

    readonly property int lit: level <= 0 ? 0 : Math.min(4, Math.ceil(level * 4))

    // Gap between arcs, center to center
    readonly property real step: 2.5
    readonly property real lineWidth: 1.5

    width: 4 * step + lineWidth / 2
    height: 14

    Repeater {
        model: 4

        Shape {
            id: arc
            required property int index
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: arc.index < arcs.lit ? arcs.color : arcs.dimColor
                strokeWidth: arcs.lineWidth
                capStyle: ShapePath.RoundCap

                // Centered on the left edge, so the arcs fan out from the
                // speaker's cone
                PathAngleArc {
                    centerX: 0
                    centerY: arcs.height / 2
                    radiusX: (arc.index + 1) * arcs.step
                    radiusY: radiusX
                    startAngle: -45
                    sweepAngle: 90
                }
            }
        }
    }
}
