import QtQuick

// Graphite with one amber accent (not an upstream scheme). Only the active
// workspace gets a pill; occupied ones are bold white numbers and empty
// ones dim. Sliders are amber with a white handle.
Scheme {
    name: "AmberGraphite"
    background: "#141414"
    surface: "#262626"
    highlight: "#363636"
    textColor: "#e6e6e6"
    dimTextColor: "#8a8a8a"
    accent: "#e8b04f"
    occupied: "#8a8a8a"
    good: "#8fd18f"
    bad: "#ff6b6b"
    menuColor: "#1e1e1e"
    borderColor: "#3c3c3c"
    sliderFill: "#e8b04f"
    sliderKnob: "#ffffff"
    workspaceStyle: "minimal"
}
