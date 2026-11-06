import QtQuick
import qs

// Night light details for the control center, shown when its tile is
// expanded: automatic or manual, the target temperature, and what's applied
// now. The tile itself turns it on and off. Follows NightLight; hide it when
// hyprsunset isn't running (NightLight.available).
Column {
    id: nightLightSection

    width: parent.width - parent.leftPadding - parent.rightPadding
    spacing: Theme.px(8)

    // Automatic: follow the sun while on. Manual: full temperature while on.
    Item {
        enabled: NightLight.enabled
        opacity: enabled ? 1 : 0.5
        width: parent.width
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
        label: "Temperature"
        value: NightLight.active ? NightLight.appliedTemperature + " K" : "Off"
    }

    MenuInfoRow {
        visible: NightLight.enabled && NightLight.auto
        label: "Schedule"
        value: (NightLight.next.on ? "On at " : "Off at ") + Qt.formatTime(NightLight.next.time, "h:mm ap")
    }
}
