import QtQuick
import qs

// On/off switch styled to match the bar. `checked` shows the state; clicking
// emits `toggled()` and leaves updating `checked` to the owner, so it can
// follow the real setting.
Rectangle {
    id: menuSwitch

    property bool checked: false
    signal toggled()

    implicitWidth: Theme.px(36)
    implicitHeight: Theme.px(20)
    radius: height / 2
    color: checked ? Theme.accent : Theme.surface
    opacity: enabled ? 1 : 0.5

    Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

    Rectangle {
        x: menuSwitch.checked ? parent.width - width - Theme.px(3) : Theme.px(3)
        anchors.verticalCenter: parent.verticalCenter
        width: parent.height - Theme.px(6)
        height: width
        radius: width / 2
        color: menuSwitch.checked ? Theme.background : Theme.textColor

        Behavior on x { NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic } }
    }

    TapHandler {
        onTapped: menuSwitch.toggled()
    }
}
