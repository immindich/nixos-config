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

    // Fonts
    readonly property int fontSize: 14
    readonly property string iconFont: "Font Awesome 7 Free"
    readonly property int iconSize: 12
    // Text is centered including descenders, which makes it look too high
    readonly property int textOffset: 1

    // Sizes
    readonly property int bubbleHeight: 26
    readonly property int barMargin: 4      // gap between bubbles and screen edges
    // Same gap above and below the bubbles as at the sides
    readonly property int barHeight: bubbleHeight + 2 * barMargin
    readonly property int bubbleSpacing: 4  // gap between bubbles
    readonly property int workspaceSize: 20 // height of a workspace circle
    readonly property int animationDuration: 150
}
