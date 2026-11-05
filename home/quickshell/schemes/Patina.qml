import QtQuick

// Copper and verdigris, both muted to the same lightness (not an upstream
// scheme), on a green-grey. Opposite hues, but low enough in chroma that
// they read as one weathered material. Toggles and tabs fill with a faint
// copper rather than a solid one.
Scheme {
    name: "Patina"
    background: "#141716"
    surface: "#252a28"
    highlight: "#303734"
    textColor: "#dde0d9"
    dimTextColor: "#959d97"
    accent: "#cc8a5e"
    occupied: "#6e9d8f"
    good: "#8fb07a"
    bad: "#d26b5c"
    menuColor: "#1b1f1d"
    borderColor: "#333a37"
    sliderFill: "#6e9d8f"
    sliderKnob: "#dde0d9"
    selectionStyle: "check"
    fillStyle: "tint"
}
