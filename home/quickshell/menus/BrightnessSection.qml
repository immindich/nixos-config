import QtQuick
import Quickshell.Io
import qs

// Brightness slider for the control center, with a sun icon beside it. It
// follows Brightness and sets it with brightnessctl. Hide it without a
// backlight (Brightness.max is 0).
Row {
    id: brightnessSection

    width: parent.width - parent.leftPadding - parent.rightPadding
    spacing: Theme.px(10)

    // Raw backlight values; max is 0 without a backlight
    readonly property int current: Brightness.current
    readonly property int max: Brightness.max

    Text {
        id: sun
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf185" // sun
        font.family: Theme.iconFont
        font.weight: Font.Black
        font.pixelSize: Theme.iconSize + Theme.px(2)
        color: Theme.textColor
    }

    MenuSlider {
        id: brightnessSlider
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - sun.width - parent.spacing
        from: 0
        to: brightnessSection.max
        // value follows the real brightness via the Binding below
        live: true
        // start() is a no-op while the timer runs, so a drag sends at most one
        // update per interval
        onMoved: backlightApply.start()
    }

    Process {
        id: backlightSetter
        running: false
        command: ["brightnessctl", "set", Math.round(brightnessSlider.value)]
    }

    // Sends the slider's latest value shortly after it changes. If the
    // previous brightnessctl is still running (so starting it again would do
    // nothing), waits and tries again instead of dropping it.
    Timer {
        id: backlightApply
        interval: 50
        onTriggered: {
            if (backlightSetter.running)
                restart()
            else
                backlightSetter.running = true
        }
    }

    // Follow outside changes (e.g. brightness keys), but not while dragging,
    // when the real brightness lags behind the handle
    Binding {
        target: brightnessSlider
        property: "value"
        // Reapply once max is read too; before that `to` is 0 and the slider
        // clamps the value to 0. Delayed so `to` has updated by the time the
        // value is applied.
        value: brightnessSection.max > 0 ? brightnessSection.current : 0
        when: !brightnessSlider.pressed
        delayed: true
    }
}
