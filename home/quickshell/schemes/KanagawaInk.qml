import QtQuick

// Kanagawa Dragon with a single colour (not an upstream scheme): dragon
// yellow for the active workspace, open indicator and checks; occupied
// workspaces outlined in dragon blue-grey; sliders in that grey.
Scheme {
    name: "KanagawaInk"
    background: "#181616"
    surface: "#2d2c2a"
    highlight: "#3a3836"
    textColor: "#c5c9c5"
    dimTextColor: "#8a8980"
    accent: "#c4b28a"
    occupied: "#8ba4b0"
    good: "#87a987"
    bad: "#c4746e"
    menuColor: "#201f1e"
    borderColor: "#4a4845"
    sliderFill: "#8ba4b0"
    sliderKnob: "#c5c9c5"
    workspaceStyle: "ring"
    selectionStyle: "check"
    fillStyle: "tint"
}
