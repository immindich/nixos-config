pragma Singleton

import QtQuick
import Quickshell

// Shared look of the bar. Colors are Tokyo Night, as used by ashell.
Singleton {
    // Colors
    readonly property color background: "#1a1b26"   // bubbles; text on light pills
    readonly property color surface: "#24273a"      // empty workspaces
    readonly property color highlight: "#292e42"    // indicator with open menu
    readonly property color textColor: "#a9b1d6"
    readonly property color dimTextColor: "#565f89" // disconnected network
    readonly property color accent: "#7aa2f7"       // active workspace
    readonly property color occupied: "#6181c6"     // workspaces with windows
    readonly property color good: "#9ece6a"         // charging battery
    readonly property color bad: "#f7768e"          // low battery, privacy

    // Size of the whole shell. Change this number to make everything bigger
    // or smaller: every other size (icons, bubbles, menus, popups) scales
    // with it. 14 is the size everything was designed at.
    readonly property int fontSize: 14
    readonly property real uiScale: fontSize / 14
    // A size given as it is at fontSize 14, in whole pixels at the current scale
    function px(n: real): int { return Math.round(n * uiScale) }

    // Fonts
    readonly property string iconFont: "Font Awesome 7 Free"
    readonly property string brandIconFont: "Font Awesome 7 Brands" // e.g. Bluetooth
    readonly property int iconSize: px(12)
    // Text is centered including descenders, which makes it look too high
    readonly property int textOffset: px(1)

    // Sizes
    readonly property int bubbleHeight: px(26)
    // Gap between bubbles and screen edges; same as Hyprland's gaps_out, so
    // it doesn't scale
    readonly property int barMargin: 6
    // Same gap above and below the bubbles as at the sides
    readonly property int barHeight: bubbleHeight + 2 * barMargin
    readonly property int bubbleSpacing: px(4)  // gap between bubbles
    readonly property int workspaceSize: px(20) // height of a workspace circle
    readonly property int animationDuration: 150

    // Wallpaper
    readonly property string wallpaper: Quickshell.env("HOME") + "/Pictures/wallpaper.jpg"
    readonly property real wallpaperDim: 0.45 // opacity of the shade over the top
}
