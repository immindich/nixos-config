import QtQuick

// Light: warm paper with dark ink and a rust accent (not an upstream
// scheme). Occupied workspaces are taupe; chosen entries sit on a faint
// rust row.
Scheme {
    name: "Paper"
    background: "#ebe5d8"
    surface: "#d8d0c1"
    highlight: "#cec5b4"
    textColor: "#2e2a25"
    dimTextColor: "#6f675c"
    accent: "#b5502b"
    accentText: "#fbf7f0"
    occupied: "#8c8170"
    occupiedText: "#f6f1e7"
    good: "#5f7a2c"
    bad: "#b83a2e"
    menuColor: "#f3eee4"
    borderColor: "#c8bead"
    sliderFill: "#b5502b"
    sliderKnob: "#2e2a25"
    selectionStyle: "row"
}
