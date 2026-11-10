import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.menus

// System tray icons, at the start of StatusArea's row and spaced like its
// indicators. Left click activates the app (or opens its menu if that's all
// it offers), right click opens its menu, middle click is the app's
// secondary action, and scrolling is passed on to the app.
Row {
    anchors.verticalCenter: parent.verticalCenter
    // Hidden while empty, so it doesn't add a gap to StatusArea's row
    visible: SystemTray.items.values.length > 0
    // Same as StatusArea's row
    spacing: Theme.px(2)

    Repeater {
        model: SystemTray.items

        // Pill like StatusArea's indicators, marked while its menu is open
        IndicatorPill {
            id: trayItem
            required property var modelData

            implicitWidth: Theme.workspaceSize + Theme.px(8)
            implicitHeight: Theme.workspaceSize
            lit: menu.visible

            IconImage {
                anchors.centerIn: parent
                source: trayItem.modelData.icon
                implicitSize: Theme.px(16)
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    const item = trayItem.modelData
                    if (mouse.button === Qt.MiddleButton)
                        item.secondaryActivate()
                    else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu)
                            menu.toggle()
                    } else
                        item.activate()
                }
                onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
            }

            DropdownMenu {
                id: menu
                anchor.item: trayItem

                // The entries reach into the menu's padding by `inset`, so
                // their text lines up with the other menus' content, which
                // sits at the padding, rather than a row's padding further in
                Item {
                    id: listArea
                    readonly property int inset: Theme.px(8)
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    height: list.height - 2 * inset

                    // Scrolls once the entries would run off the screen
                    Flickable {
                        id: list
                        x: -listArea.inset
                        y: -listArea.inset
                        width: listArea.width + 2 * listArea.inset
                        height: Math.min(entries.implicitHeight, menu.maxContentHeight + 2 * listArea.inset)
                        contentHeight: entries.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        TrayMenuEntries {
                            id: entries
                            width: list.width
                            handle: trayItem.modelData.menu
                            menu: menu
                        }
                    }
                }
            }
        }
    }
}
