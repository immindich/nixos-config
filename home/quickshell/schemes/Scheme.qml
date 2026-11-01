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
}
