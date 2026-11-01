// Concave corner that rounds a drop-down's side into the bar above it.
import QtQuick
import QtQuick.Shapes

Shape {
    id: flare
    property bool rightSide: false
    property int size: 24
    property color fill: "transparent"

    width: size
    height: size
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: flare.fill
        strokeColor: "transparent"
        startX: 0; startY: 0
        PathLine { x: flare.size; y: 0 }
        PathLine { x: flare.size; y: flare.rightSide ? 0 : flare.size }
        PathArc {
            x: 0
            y: flare.rightSide ? flare.size : 0
            radiusX: flare.size
            radiusY: flare.size
            direction: PathArc.Counterclockwise
        }
    }
}
