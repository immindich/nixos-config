import QtQuick

// Scroll wheel handler that reports whole notches: `stepped(1)` for each
// notch up (away from you) and `stepped(-1)` for each notch down. Touchpads
// send many small events, so partial notches add up until one is complete.
// Attach it to an item by declaring it as a child.
WheelHandler {
    signal stepped(int direction)
    property real pending: 0

    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

    onWheel: event => {
        pending += event.angleDelta.y
        while (pending >= 120) {
            pending -= 120
            stepped(1)
        }
        while (pending <= -120) {
            pending += 120
            stepped(-1)
        }
    }
}
