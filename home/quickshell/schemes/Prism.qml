import QtQuick

// Colourful but calm (not an upstream scheme): each workspace keeps a
// colour of its own, five soft hues of the same lightness, so busy
// workspaces read as a set rather than a clash. The active one is a pale
// pill that none of them compete with. Menus use only the apricot.
Scheme {
    name: "Prism"
    background: "#161514"
    surface: "#292826"
    highlight: "#353331"
    textColor: "#e6e1d8"
    dimTextColor: "#9a958c"
    accent: "#dca17e"
    occupied: "#a8a49b"
    activeWorkspace: "#ece6dc"
    workspaceColors: ["#dca17e", "#cdb672", "#98bd8e", "#82b7b2", "#b4a2d1"]
    good: "#98bd8e"
    bad: "#e07b72"
    menuColor: "#1d1c1a"
    borderColor: "#393734"
    sliderFill: "#dca17e"
    sliderKnob: "#ece6dc"
    selectionStyle: "row"
}
