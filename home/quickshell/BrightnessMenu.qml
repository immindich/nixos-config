import QtQuick
import Quickshell.Io

// Brightness slider, opened from the brightness indicator. Set `anchor.item`
// to the indicator and pass in the backlight's raw `current` and `max` values;
// the menu sets brightness itself with brightnessctl.
DropdownMenu {
    id: brightnessMenu

    property int current: 0
    property int max: 0

    MenuHeading { text: "Brightness" }

    MenuSlider {
        id: brightnessSlider
        from: 0
        to: brightnessMenu.max
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
        value: brightnessMenu.max > 0 ? brightnessMenu.current : 0
        when: !brightnessSlider.pressed
        delayed: true
    }
}
