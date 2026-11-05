import QtQuick
import Quickshell.Io
import qs

// Brightness slider and night light controls, opened from the brightness
// indicator. Set `anchor.item` to the indicator and pass in the backlight's
// raw `current` and `max` values; the menu sets brightness itself with
// brightnessctl. The night light section follows NightLight (on/off,
// automatic or manual, target temperature) and is hidden
// when hyprsunset isn't running.
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

    Item {
        visible: NightLight.available
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: Math.max(nightLightHeading.implicitHeight, nightLightSwitch.implicitHeight)

        MenuHeading {
            id: nightLightHeading
            anchors.verticalCenter: parent.verticalCenter
            text: "Night light"
        }

        MenuSwitch {
            id: nightLightSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: NightLight.enabled
            onToggled: NightLight.enabled = !NightLight.enabled
        }
    }

    // Automatic: follow the sun while on. Manual: full temperature while on.
    Item {
        visible: NightLight.available
        enabled: NightLight.enabled
        opacity: enabled ? 1 : 0.5
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: Math.max(autoLabel.implicitHeight, autoSwitch.implicitHeight)

        Text {
            id: autoLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Automatic"
            font.pixelSize: Theme.fontSize
            color: Theme.dimTextColor
        }

        MenuSwitch {
            id: autoSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: NightLight.auto
            onToggled: NightLight.auto = !NightLight.auto
        }
    }

    // Sets the target temperature; in automatic mode the filter fades toward
    // it at sunset
    MenuSlider {
        id: temperatureSlider
        visible: NightLight.available
        enabled: NightLight.enabled
        opacity: enabled ? 1 : 0.5
        from: NightLight.minTemperature
        to: NightLight.maxTemperature
        stepSize: 100
        live: true
        // Throttled in NightLight, so every move can be forwarded
        onMoved: NightLight.temperature = value
    }

    Binding {
        target: temperatureSlider
        property: "value"
        value: NightLight.temperature
        when: !temperatureSlider.pressed
    }

    MenuInfoRow {
        visible: NightLight.available
        label: "Temperature"
        value: NightLight.active ? NightLight.appliedTemperature + " K" : "Off"
    }

    MenuInfoRow {
        visible: NightLight.available && NightLight.enabled && NightLight.auto
        label: "Schedule"
        value: (NightLight.next.on ? "On at " : "Off at ") + Qt.formatTime(NightLight.next.time, "h:mm ap")
    }
}
