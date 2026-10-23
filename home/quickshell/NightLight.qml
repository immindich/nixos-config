pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// hyprsunset's blue-light filter, controlled through `hyprctl hyprsunset`.
// hyprsunset can't be asked whether it's applying a filter (`identity` leaves
// the reported temperature unchanged), so this singleton owns the on/off
// state and temperature and pushes them to hyprsunset whenever they change.
// They're kept across config reloads; a fresh shell starts with the filter off.
Singleton {
    id: nightLight

    // False until hyprsunset answers; hides the controls when it isn't running
    property bool available: false
    property alias enabled: persist.enabled
    property alias temperature: persist.temperature // kelvin, used while enabled

    readonly property int minTemperature: 2000
    readonly property int maxTemperature: 6500

    PersistentProperties {
        id: persist
        reloadableId: "nightLight"
        property bool enabled: false
        property int temperature: 4000
        onEnabledChanged: apply.start()
        onTemperatureChanged: if (enabled) apply.start()
    }

    // Also push the state when hyprsunset first shows up, since the default
    // 6000K it starts with is a visible tint
    onAvailableChanged: if (available) apply.start()

    Process {
        id: setter
        running: false
        command: nightLight.enabled
            ? ["hyprctl", "hyprsunset", "temperature", String(nightLight.temperature)]
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
