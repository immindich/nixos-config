import Quickshell
import Quickshell.Widgets

// Icon of the app with the given app id (a window class or D-Bus app name):
// the app id names the desktop entry, which names the icon. A generic
// program icon when there's no entry.
IconImage {
    property string appId: ""

    readonly property var desktopEntry: {
        // The lookup isn't reactive on its own; depend on the index so it
        // runs again once the entries are scanned, which takes a moment
        // after the shell starts
        DesktopEntries.applications.values
        return appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
    }

    source: Quickshell.iconPath(desktopEntry?.icon ?? "", "application-x-executable")
}
