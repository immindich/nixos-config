import QtQuick

// Greyscale with a white accent (not an upstream scheme). Only the active
// workspace gets a pill; occupied ones are bold numbers.
Scheme {
    name: "Graphite"
    background: "#141414"
    surface: "#262626"
    highlight: "#363636"
    textColor: "#e6e6e6"
    dimTextColor: "#9a9a9a"
    accent: "#ffffff"
    occupied: "#8a8a8a"
    good: "#8fd18f"
    bad: "#ff6b6b"
    menuColor: "#1e1e1e"
    borderColor: "#3c3c3c"
    workspaceStyle: "minimal"
}
