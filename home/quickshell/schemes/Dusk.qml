import QtQuick

// Two neighbouring hues at the same lightness and softness (not an
// upstream scheme): rose for active, lavender for occupied and slider fill.
// Being 60 degrees apart rather than opposite, they sit together without
// buzzing.
Scheme {
    name: "Dusk"
    background: "#17141b"
    surface: "#2a2530"
    highlight: "#362f3d"
    textColor: "#e2dbe6"
    dimTextColor: "#9f96a7"
    accent: "#e59aa9"
    occupied: "#ae9bd3"
    good: "#9cc4a4"
    bad: "#ec806f"
    menuColor: "#1f1b24"
    borderColor: "#3b3343"
    sliderFill: "#ae9bd3"
    sliderKnob: "#e59aa9"
}
