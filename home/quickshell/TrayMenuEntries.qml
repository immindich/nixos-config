import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Entries of a tray item's menu, for use inside a DropdownMenu. Submenus
// expand inline below their entry, indented.
Column {
    id: entries

    property var handle: null // QsMenuHandle of the menu to show
    property var menu: null   // DropdownMenu to close after an entry is clicked
    property int depth: 0     // submenu nesting level, for indentation

    width: parent ? parent.width - (parent.leftPadding ?? 0) - (parent.rightPadding ?? 0) : 0

    QsMenuOpener {
        id: opener
        menu: entries.handle
    }

    Repeater {
        model: opener.children

        Column {
            id: entry
            required property var modelData
            property bool expanded: false
            width: entries.width

            // Separator
            Item {
                visible: entry.modelData.isSeparator
                width: parent.width
                height: 9
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 1
                    color: Theme.surface
                }
            }

            Rectangle {
                visible: !entry.modelData.isSeparator
                width: parent.width
                height: 28
                radius: 8
                color: hover.hovered && entry.modelData.enabled ? Theme.highlight : "transparent"
                opacity: entry.modelData.enabled ? 1 : 0.5

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8 + entries.depth * 12
                    anchors.rightMargin: 8
                    spacing: 8

                    // Checkbox / radio button state
                    Text {
                        visible: entry.modelData.buttonType !== QsMenuButtonType.None
                        font.family: Theme.iconFont
                        font.weight: Font.Black
                        font.pixelSize: Theme.iconSize
                        color: Theme.accent
                        Layout.preferredWidth: Theme.iconSize + 2
                        horizontalAlignment: Text.AlignHCenter
                        text: entry.modelData.checkState !== Qt.Checked ? ""
                            : entry.modelData.buttonType === QsMenuButtonType.RadioButton ? "" // circle-dot
                            : "" // check
                    }

                    IconImage {
                        visible: entry.modelData.icon !== ""
                        source: entry.modelData.icon
                        implicitSize: 16
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        Layout.topMargin: Theme.textOffset
                        text: entry.modelData.text
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSize
                        color: Theme.textColor
                    }

                    // Submenu arrow
                    Text {
                        visible: entry.modelData.hasChildren
                        font.family: Theme.iconFont
                        font.weight: Font.Black
                        font.pixelSize: Theme.iconSize - 2
                        color: Theme.dimTextColor
                        text: entry.expanded ? "" : "" // chevron-down : chevron-right
                    }
                }

                HoverHandler { id: hover }

                TapHandler {
                    enabled: entry.modelData.enabled
                    onTapped: {
                        if (entry.modelData.hasChildren) {
                            entry.expanded = !entry.expanded
                        } else {
                            entry.modelData.triggered()
                            if (entries.menu)
                                entries.menu.visible = false
                        }
                    }
                }
            }

            Loader {
                active: entry.expanded
                width: parent.width
                source: "TrayMenuEntries.qml"
                onLoaded: {
                    item.handle = entry.modelData
                    item.menu = entries.menu
                    item.depth = entries.depth + 1
                }
            }
        }
    }
}
