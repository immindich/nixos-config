import QtQuick

// One hue in several strengths (not an upstream scheme): warm charcoal, an
// ember orange for what's active and a dark clay of the same hue for
// occupied workspaces, so the two never compete. Sliders are ember with a
// cream handle; chosen entries sit on a faint ember row.
Scheme {
    name: "Ember"
    background: "#15120f"
    surface: "#2a2520"
    highlight: "#362f29"
    textColor: "#e4dccf"
    dimTextColor: "#a39889"
    accent: "#e0894a"
    occupied: "#6b4a35"
    occupiedText: "#f0dccb"
    good: "#a3b06b"
    bad: "#d9604c"
    menuColor: "#1e1a16"
    borderColor: "#3a322b"
    sliderFill: "#e0894a"
    sliderKnob: "#f2e6d8"
    selectionStyle: "row"
}
