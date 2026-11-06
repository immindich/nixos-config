pragma Singleton

import QtQuick
import Quickshell
import "schemes"

// Shared look of the bar. The colours come from the scheme named in
// `scheme`; everything else about the look is an option below. The options
// aren't readonly so ThemeTweaker (SUPER+SHIFT+T) can try them live; a
// reload brings back the values here.
Singleton {
    // Colour scheme: the name of one of the files in schemes/
    property string scheme: "Graphite"
    readonly property list<Scheme> schemes: [
        AyuMirage {}, CatppuccinMocha {}, Everforest {}, Flexoki {}, Graphite {},
        GruvboxMaterial {}, Horizon {}, KanagawaDragon {}, KanagawaWave {}, Melange {},
        MonokaiPro {}, Nord {}, Oxocarbon {}, RosePine {}, SolarizedDark {}, TokyoNight {},
        TomorrowNight {}, Zenburn {},
        AmberGraphite {}, Dusk {}, Ember {}, FlexokiCalm {}, KanagawaInk {}, Moss {},
        Paper {}, Patina {}, Prism {}, Sumi {}
    ]
    readonly property Scheme colors: {
        const found = schemes.find(s => s.name === scheme)
        if (!found)
            console.warn("Theme: no colour scheme named", scheme)
        return found ?? schemes[0]
    }

    // Colours (see schemes/Scheme.qml for what each is used for)
    readonly property color background: colors.background
    readonly property color surface: colors.surface
    readonly property color highlight: colors.highlight
    readonly property color textColor: colors.textColor
    readonly property color dimTextColor: colors.dimTextColor
    readonly property color accent: colors.accent
    readonly property color occupied: colors.occupied
    readonly property color good: colors.good
    readonly property color bad: colors.bad
    readonly property color menuColor: colors.menuColor
    readonly property color borderColor: colors.borderColor
    readonly property color accentText: colors.accentText
    readonly property color occupiedText: colors.occupiedText
    readonly property color sliderFill: colors.sliderFill
    readonly property color sliderKnob: colors.sliderKnob
    readonly property color activeWorkspace: colors.activeWorkspace
    // Colour of an occupied workspace with the given id
    function workspaceColor(id: int): color {
        const own = colors.workspaceColors
        return own.length > 0 && id > 0 ? own[(id - 1) % own.length] : occupied
    }

    // `c` at opacity `a`, for faint fills
    function tint(c: color, a: real): color { return Qt.rgba(c.r, c.g, c.b, a) }

    // How workspaces, chosen list entries and filled controls are
    // highlighted (see schemes/Scheme.qml); empty for the scheme's own choice
    property string workspaceStyle: ""
    property string selectionStyle: ""
    property string fillStyle: ""
    readonly property string workspaceLook: workspaceStyle || colors.workspaceStyle
    readonly property string selectionLook: selectionStyle || colors.selectionStyle
    readonly property string fillLook: fillStyle || colors.fillStyle

    // A chosen list entry: its text and icon, the check beside it, and the
    // row behind it
    readonly property color selectedText: selectionLook === "accent" ? colors.selected : textColor
    readonly property color selectedMark: colors.selected
    readonly property color selectedRow: selectionLook === "row" ? tint(colors.selected, 0.16) : "transparent"
    // A tab, toggle button or switch that's on, and what's drawn on it
    readonly property color controlFill: fillLook === "tint" ? tint(accent, 0.32) : accent
    readonly property color controlText: fillLook === "tint" ? accent : accentText

    // How a menu hangs off the bar:
    //   "float"  a menuGap below the bar
    //   "caret"  floats, with a beak pointing at its indicator
    //   "drawer" flush with the bar, square corners where they meet
    //   "tab"    a drawer joined to its indicator by a tab through the bar
    //   "flush"  hangs just off the indicator, rounded (the original look)
    property string menuStyle: "drawer"
    // Gap between the bar and a floating menu; same as the bar's margin by
    // default, so it doesn't scale
    property int menuGap: barMargin
    // Outline around menus, tooltips, notifications and the OSD, in
    // device-independent pixels (0 for none), in borderColor
    property int menuBorder: 1
    property bool menuShadow: false
    // Below 1 the menus show what's behind them, blurred by Hyprland (the
    // layer rules in home/hyprland.nix)
    property real menuOpacity: 0.85
    // Accent stripe along the edge of a menu that faces the bar
    property bool menuAccentEdge: false
    // How an indicator shows that its menu is open:
    //   "accent"    glyph in the accent colour
    //   "filled"    accent pill with a dark glyph, like the active workspace
    //   "underline" accent stroke under the glyph
    //   "pill"      lighter pill behind the glyph (the original look)
    //   "tab"       tab in the menu's colour, for menuStyle "tab"
    property string activeStyle: "accent"

    // Size of the whole shell. Change this number to make everything bigger
    // or smaller: every other size (icons, bubbles, menus, popups) scales
    // with it. 14 is the size everything was designed at.
    property int fontSize: 14
    readonly property real uiScale: fontSize / 14
    // A size given as it is at fontSize 14, in whole pixels at the current scale
    function px(n: real): int { return Math.round(n * uiScale) }

    // Fonts
    readonly property string iconFont: "Font Awesome 7 Free"
    readonly property string brandIconFont: "Font Awesome 7 Brands" // e.g. Bluetooth
    readonly property int iconSize: px(12)
    // Text is centered including descenders, which makes it look too high
    readonly property int textOffset: px(1)

    // Screen edge the bar sits on: "top" or "bottom". Menus, tooltips and
    // the workspace window list open toward the middle of the screen.
    property string barPosition: "top"
    readonly property bool barOnBottom: barPosition === "bottom"
    readonly property color barColor: background

    // Sizes
    // Height of the bar's groups (session button, workspaces, window title,
    // status area)
    readonly property int bubbleHeight: px(26)
    // Gap between the bar's groups and its ends; same as Hyprland's
    // gaps_out, so it doesn't scale
    readonly property int barMargin: 6
    // Same gap above and below the groups as at the ends
    readonly property int barHeight: bubbleHeight + 2 * barMargin
    readonly property int bubbleSpacing: px(4)  // gap between groups
    readonly property int workspaceSize: px(20) // height of a workspace circle
    readonly property int animationDuration: 150
    readonly property int menuOpenDuration: 90 // menus fade and slide in

    // Wallpaper
    readonly property string wallpaper: Quickshell.env("HOME") + "/Pictures/wallpaper.jpg"
    readonly property real wallpaperDim: 0.45 // opacity of the shade over the top
}
