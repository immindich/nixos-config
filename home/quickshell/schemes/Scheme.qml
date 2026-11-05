import QtQuick

// A colour scheme for the shell: one file per scheme in this directory,
// all listed in Theme.schemes, with Theme.scheme naming the one in use.
// The defaults are Flexoki Dark.
QtObject {
    property string name: "Flexoki"
    property color background: "#100f0f"   // bar and bubbles; text on light pills
    property color surface: "#343331"      // empty workspaces, buttons, fields
    property color highlight: "#403e3c"    // hovered entries; indicator with open menu (activeStyle "pill")
    property color textColor: "#cecdc3"
    property color dimTextColor: "#9f9d96" // labels, disconnected network
    property color accent: "#da702c"       // active workspace, switches, open indicator
    property color occupied: "#d0a215"     // workspaces with windows
    property color good: "#879a39"         // charging battery
    property color bad: "#d14d41"          // low battery, privacy
    property color menuColor: "#1c1b1a"    // menus, tooltips, notifications, OSD
    property color borderColor: "#403e3c"  // their outline (Theme.menuBorder)

    // Colours for particular parts. They default to the ones above, so a
    // scheme only sets those it wants to differ.
    property color accentText: background    // text and glyphs on accent fills
    property color occupiedText: background // number on an occupied workspace
    property color selected: accent        // chosen entry in a list (default device, connected network)
    property color sliderFill: occupied    // slider, left of the handle
    property color sliderKnob: accent      // slider handle
    property color activeWorkspace: accent
    // A colour per workspace (1 takes the first, wrapping round) in place
    // of `occupied`; empty for one colour for all
    property var workspaceColors: []

    // How the scheme highlights things; Theme options of the same name
    // override these when set.
    //   workspaceStyle: "filled"  occupied workspaces in a solid pill
    //                   "tint"    occupied in a faint pill of their colour
    //                   "ring"    occupied outlined, empty ones bare
    //                   "minimal" only the active workspace has a pill
    //   selectionStyle: "accent"  chosen entry's text, icon and check in `selected`
    //                   "row"     chosen entry on a faint row of `selected`
    //                   "check"   only the check mark in `selected`
    //   fillStyle:      "solid"   tabs, switches and toggles fill with accent
    //                   "tint"    they fill with a faint accent, accent text
    property string workspaceStyle: "filled"
    property string selectionStyle: "accent"
    property string fillStyle: "solid"
}
