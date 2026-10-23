pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Current conditions and forecast from Open-Meteo, for wherever GeoClue says
// the laptop is (via the where-am-i wrapper in home/common.nix). Refreshed
// every 15 minutes; a failed refresh (no network yet at login, say) is retried
// after a minute. `available` is false until the first forecast arrives.
Singleton {
    id: weather

    // Open-Meteo's unit names
    readonly property string temperatureUnit: "fahrenheit"
    readonly property string windSpeedUnit: "mph"

    property bool available: false
    property date updated
    // Last known location; kept if GeoClue has no answer on a later refresh
    property real latitude: NaN
    property real longitude: NaN

    // Current conditions
    property int temperature: 0
    property int apparentTemperature: 0
    property int humidity: 0        // percent
    property real windSpeed: 0
    property int code: 0            // WMO weather code
    property bool day: true
    // Today
    property int high: 0
    property int low: 0
    property int precipitationChance: 0 // percent, max over the day
    // The next few hours, as {label, code, day, temperature}
    property var hours: []

    readonly property string description: describe(code)
    readonly property string icon: iconFor(code, day)

    function describe(code) {
        if (code === 0) return "Clear"
        if (code === 1) return "Mainly clear"
        if (code === 2) return "Partly cloudy"
        if (code === 3) return "Overcast"
        if (code === 45 || code === 48) return "Fog"
        if (code >= 51 && code <= 55) return "Drizzle"
        if (code === 56 || code === 57) return "Freezing drizzle"
        if (code === 61) return "Light rain"
        if (code === 63) return "Rain"
        if (code === 65) return "Heavy rain"
        if (code === 66 || code === 67) return "Freezing rain"
        if (code === 71) return "Light snow"
        if (code === 73) return "Snow"
        if (code === 75) return "Heavy snow"
        if (code === 77) return "Snow grains"
        if (code === 80) return "Light showers"
        if (code === 81) return "Showers"
        if (code === 82) return "Heavy showers"
        if (code === 85 || code === 86) return "Snow showers"
        if (code === 95) return "Thunderstorm"
        if (code === 96 || code === 99) return "Thunderstorm with hail"
        return "Unknown"
    }

    // Font Awesome solid glyph for a weather code
    function iconFor(code, day) {
        if (code <= 1) return day ? "" : ""             // sun : moon
        if (code === 2) return day ? "" : ""            // cloud-sun : cloud-moon
        if (code === 3) return ""                             // cloud
        if (code <= 48) return ""                             // smog
        if (code <= 61 || code === 80) return day ? "" : "" // cloud-sun-rain : cloud-moon-rain
        if (code <= 67 || code === 81) return ""              // cloud-rain
        if (code <= 77 || code === 85 || code === 86) return "" // snowflake
        if (code === 82) return ""                            // cloud-showers-heavy
        return ""                                             // cloud-bolt
    }

    Timer {
        id: refresh
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: locate.running = true
    }
    Timer {
        id: retry
        interval: 60 * 1000
        onTriggered: locate.running = true
    }

    // Prints "<lat> <lon>", or nothing if GeoClue has no fix
    Process {
        id: locate
        command: ["where-am-i"]
        // The collector below never finishes if the command fails to start,
        // so also retry when the process ends without a fetch under way
        onRunningChanged: {
            if (!running && !weather.fetching && isNaN(weather.latitude))
                retry.start()
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                const lat = parseFloat(parts[0])
                const lon = parseFloat(parts[1])
                if (!isNaN(lat) && !isNaN(lon)) {
                    weather.latitude = lat
                    weather.longitude = lon
                }
                if (isNaN(weather.latitude))
                    retry.start()
                else
                    weather.fetch()
            }
        }
    }

    property bool fetching: false

    function fetch() {
        if (fetching)
            return
        fetching = true
        retry.stop()
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            fetching = false
            if (xhr.status === 200) {
                try {
                    apply(JSON.parse(xhr.responseText))
                    return
                } catch (e) {
                    console.warn("weather: bad response:", e)
                }
            } else {
                console.warn("weather: request failed with status", xhr.status)
            }
            retry.start()
        }
        xhr.open("GET", "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + latitude + "&longitude=" + longitude
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
            + "&hourly=temperature_2m,weather_code,is_day"
            + "&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max"
            + "&temperature_unit=" + temperatureUnit + "&wind_speed_unit=" + windSpeedUnit
            + "&timezone=auto&forecast_days=2")
        xhr.send()
    }

    function apply(data) {
        const c = data.current
        temperature = Math.round(c.temperature_2m)
        apparentTemperature = Math.round(c.apparent_temperature)
        humidity = c.relative_humidity_2m
        windSpeed = c.wind_speed_10m
        code = c.weather_code
        day = c.is_day === 1

        high = Math.round(data.daily.temperature_2m_max[0])
        low = Math.round(data.daily.temperature_2m_min[0])
        precipitationChance = data.daily.precipitation_probability_max[0] ?? 0

        // Times are local ISO strings like "2026-10-23T14:00". Start the hourly
        // list from the hour after the current reading's.
        const h = data.hourly
        const now = h.time.indexOf(c.time.slice(0, 13) + ":00")
        const next = []
        for (let i = now + 1; i < h.time.length && next.length < 6; i++) {
            const hour = parseInt(h.time[i].slice(11, 13))
            next.push({
                label: (hour % 12 || 12) + (hour < 12 ? "am" : "pm"),
                code: h.weather_code[i],
                day: h.is_day[i] === 1,
                temperature: Math.round(h.temperature_2m[i]),
            })
        }
        hours = next

        updated = new Date()
        available = true
    }
}
