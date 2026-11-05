pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// hyprsunset's blue-light filter, controlled through `hyprctl hyprsunset`.
// hyprsunset can't be asked whether it's applying a filter (`identity` leaves
// the reported temperature unchanged), so this singleton owns the state and
// pushes it to hyprsunset whenever it changes; hyprsunset has no profiles of
// its own.
//
// `enabled` turns the night light on or off altogether. While it's on,
// automatic mode makes the filter follow the sun: it fades in over the
// `fadeMinutes` around sunset and out around sunrise, using Weather's times
// for the current location (fixed fallback times until there is one). In
// manual mode the filter sits at `temperature` the whole time it's on. All of
// it is kept across config reloads; a fresh shell starts on, in automatic
// mode.
Singleton {
    id: nightLight

    // False until hyprsunset answers; hides the controls when it isn't running
    property bool available: false
    property alias enabled: persist.enabled
    property alias auto: persist.auto               // follow the sun while enabled
    property alias temperature: persist.temperature // kelvin, at full night

    readonly property int minTemperature: 2000
    readonly property int maxTemperature: 6500

    readonly property int fadeMinutes: 60
    readonly property int fallbackSunrise: 7 * 60   // minutes after midnight
    readonly property int fallbackSunset: 19 * 60
    readonly property int sunrise: Weather.sunriseMinutes >= 0 ? Weather.sunriseMinutes : fallbackSunrise
    readonly property int sunset: Weather.sunsetMinutes >= 0 ? Weather.sunsetMinutes : fallbackSunset

    // Wall-clock time (ms), refreshed every minute; bindings below follow it
    property double now: Date.now()

    // The schedule's next change, as { time: Date, on: bool }
    readonly property var next: nextTransition(now)
    // How far into night the filter is, 0 (off) to 1 (full temperature)
    readonly property real factor: !enabled ? 0 : auto ? nightFactor(now) : 1
    readonly property bool active: factor > 0
    readonly property int appliedTemperature:
        Math.round((maxTemperature - factor * (maxTemperature - temperature)) / 50) * 50

    PersistentProperties {
        id: persist
        reloadableId: "nightLight"
        property bool enabled: true
        property bool auto: true
        property int temperature: 4000
    }

    onActiveChanged: apply.start()
    onAppliedTemperatureChanged: if (active) apply.start()

    // Also push the state when hyprsunset first shows up, since the default
    // 6000K it starts with is a visible tint
    onAvailableChanged: if (available) apply.start()

    // 0 by day, 1 by night, ramping linearly across the fade around sunrise
    // and sunset
    function nightFactor(ms) {
        const d = new Date(ms)
        const m = d.getHours() * 60 + d.getMinutes() + d.getSeconds() / 60
        const ramp = centre => Math.min(1, Math.max(0, (m - centre + fadeMinutes / 2) / fadeMinutes))
        return 1 - ramp(sunrise) + ramp(sunset)
    }

    // The start of the next fade after `ms`
    function nextTransition(ms) {
        const d = new Date(ms)
        const at = (day, minutes) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + day,
                                              0, minutes - fadeMinutes / 2)
        const candidates = [
            { time: at(0, sunrise), on: false },
            { time: at(0, sunset), on: true },
            { time: at(1, sunrise), on: false },
        ]
        for (const c of candidates)
            if (c.time.getTime() > ms)
                return c
        return { time: at(1, sunset), on: true }
    }

    Timer {
        interval: 60 * 1000
        repeat: true
        running: true
        onTriggered: nightLight.now = Date.now()
    }

    Process {
        id: setter
        running: false
        command: nightLight.active
            ? ["hyprctl", "hyprsunset", "temperature", String(nightLight.appliedTemperature)]
            : ["hyprctl", "hyprsunset", "identity"]
    }

    // Sends the latest state shortly after it changes, so a slider drag sends
    // at most one command per interval; retries if the previous one is still
    // running instead of dropping the update.
    Timer {
        id: apply
        interval: 50
        onTriggered: {
            if (!nightLight.available)
                return
            if (setter.running)
                restart()
            else
                setter.running = true
        }
    }

    // hyprsunset may start after the shell at login, so keep asking until it
    // answers with a temperature
    Process {
        id: probe
        running: true
        command: ["hyprctl", "hyprsunset", "temperature"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!isNaN(parseInt(text)))
                    nightLight.available = true
            }
        }
    }
    Timer {
        interval: 5000
        repeat: true
        running: !nightLight.available
        onTriggered: probe.running = true
    }
}
