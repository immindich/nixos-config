import QtQuick

// Ink and vermilion, like a woodblock print (not an upstream scheme):
// warm greys throughout and one red seal colour, used only for the active
// workspace, the open indicator and check marks. Occupied workspaces are
// outlined in grey; sliders are bone with a vermilion handle.
Scheme {
    name: "Sumi"
    background: "#131312"
    surface: "#262624"
    highlight: "#333331"
    textColor: "#e3e1da"
    dimTextColor: "#8f8d86"
    accent: "#d4553a"
    accentText: "#f6f1e8"
    occupied: "#8f8d86"
    good: "#9aaa6a"
    bad: "#d4553a"
    menuColor: "#1b1b1a"
    borderColor: "#393936"
    sliderFill: "#c2beb3"
    sliderKnob: "#d4553a"
    workspaceStyle: "ring"
    selectionStyle: "check"
}
