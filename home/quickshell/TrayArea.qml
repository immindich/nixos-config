import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.menus

// System tray icons in a bubble, hidden when there are none. Left click
// activates the app (or opens its menu if that's all it offers), right click
// opens its menu, middle click is the app's secondary action, and scrolling
// is passed on to the app.
Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    visible: SystemTray.items.values.length > 0
    implicitWidth: row.implicitWidth + Theme.px(12)
    implicitHeight: Theme.bubbleHeight
    radius: height / 2
    color: Theme.background

    Row {
        id: row
        anchors.centerIn: parent
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

                    // Scrolls once the entries would run off the screen
                    Flickable {
                        id: list
                        width: parent.width - parent.leftPadding - parent.rightPadding
                        height: Math.min(entries.implicitHeight, menu.maxContentHeight)
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
