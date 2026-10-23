import QtQuick
import QtQuick.Controls
import qs

// Slider styled to match the bar, sized to fill a DropdownMenu's width
Slider {
    id: slider

    width: parent.width - parent.leftPadding - parent.rightPadding
    padding: 0
    implicitHeight: Theme.workspaceSize

    background: Rectangle {
        x: slider.leftPadding
        y: slider.topPadding + (slider.availableHeight - height) / 2
        width: slider.availableWidth
        height: 6
        radius: height / 2
        color: Theme.surface

        // Filled part, left of the handle
        Rectangle {
            width: slider.handle.x + slider.handle.width / 2 - parent.x
            height: parent.height
            radius: height / 2
            color: Theme.occupied
        }
    }

    handle: Rectangle {
        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: slider.topPadding + (slider.availableHeight - height) / 2
        width: 16
        height: 16
        radius: width / 2
        color: slider.pressed ? Theme.textColor : Theme.accent

        Behavior on color { ColorAnimation { duration: Theme.animationDuration } }
    }
}
