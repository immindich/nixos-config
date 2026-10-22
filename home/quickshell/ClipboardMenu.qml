import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Clipboard history from cliphist, opened from the clipboard indicator or
// with `qs ipc call clipboard toggle` (SUPER+SHIFT+V). Type to filter, pick
// with Up/Down or the mouse; Enter or a click copies the entry back to the
// clipboard. ✕ on a row deletes it, "Clear" deletes them all. Images are
// shown as thumbnails.
DropdownMenu {
    id: clipboardMenu

    takesKeyboard: true
    implicitWidth: 380

    // Image entries are decoded here for their thumbnails, once per login
    readonly property string thumbDir: Quickshell.env("XDG_RUNTIME_DIR") + "/cliphist-thumbs"

    // {id, preview, image, label} per entry, newest first
    property var entries: []
    readonly property var results: {
        const query = searchInput.text.toLowerCase()
        return query === "" ? entries : entries.filter(e => e.label.toLowerCase().includes(query))
    }
    // Index of the highlighted result
    property int selected: 0

    function reload() {
        lister.running = true
    }

    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "_", entry.id])
        clipboardMenu.visible = false
    }

    function remove(entry) {
        // `cliphist delete` takes list lines on stdin
        deleter.command = ["sh", "-c", "printf '%s\\t%s\\n' \"$1\" \"$2\" | cliphist delete", "_", entry.id, entry.preview]
        deleter.running = true
    }

    onVisibleChanged: {
        searchInput.text = ""
        selected = 0
        if (visible) {
            reload()
            searchInput.forceActiveFocus()
        }
    }
    onResultsChanged: selected = Math.min(selected, Math.max(results.length - 1, 0))
    onSelectedChanged: list.ensureVisible(selected)

    // Only the menu on the focused screen answers
    IpcHandler {
        target: "clipboard"
        enabled: clipboardMenu.anchor.item?.QsWindow.window?.screen?.name === Hyprland.focusedMonitor?.name
        function toggle(): void { clipboardMenu.toggle() }
    }

    // `cliphist list` prints "id<TAB>preview" per line, newest first, with
    // whitespace collapsed and long entries cut off with "…". Images show as
    // "[[ binary data 315 B png 320x200 ]]".
    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                clipboardMenu.entries = text.split("\n").filter(line => line.includes("\t")).map(line => {
                    const tab = line.indexOf("\t")
                    const preview = line.slice(tab + 1)
                    const image = preview.match(/^\[\[ binary data (\S+ \S+) (\S+) (\S+) \]\]$/)
                    return {
                        id: line.slice(0, tab),
                        preview: preview,
                        image: image !== null,
                        label: image ? `Image (${image[2]} ${image[3]}, ${image[1]})` : preview
                    }
                })
            }
        }
    }

    Process {
        id: deleter
        onExited: clipboardMenu.reload()
    }

    Process {
        id: wiper
        command: ["sh", "-c", "cliphist wipe && rm -rf \"$1\"", "_", clipboardMenu.thumbDir]
        onExited: clipboardMenu.reload()
    }

    // Heading with the Clear button
    Item {
        width: parent.width - parent.leftPadding - parent.rightPadding
        implicitHeight: Math.max(heading.implicitHeight, 24)

        MenuHeading {
            id: heading
            anchors.verticalCenter: parent.verticalCenter
            text: "Clipboard"
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: clipboardMenu.entries.length > 0
            width: clearLabel.implicitWidth + 20
            height: 24
            radius: height / 2
            color: clearHover.hovered ? Theme.highlight : Theme.surface

            Text {
                id: clearLabel
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Theme.textOffset
                text: "Clear"
                font.pixelSize: Theme.fontSize - 2
                color: Theme.textColor
            }

            HoverHandler { id: clearHover }
            TapHandler { onTapped: wiper.running = true }
        }
    }

    // Search field, as in the start menu
    Rectangle {
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: 30
        radius: 8
        color: Theme.surface
        border.width: searchInput.activeFocus ? 1 : 0
        border.color: Theme.accent

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "" // magnifying-glass
            font.family: Theme.iconFont
            font.weight: Font.Black
            font.pixelSize: Theme.iconSize
            color: Theme.dimTextColor
        }

        TextInput {
            id: searchInput
            anchors.fill: parent
            anchors.leftMargin: 32
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            font.pixelSize: Theme.fontSize
            color: Theme.textColor
            selectionColor: Theme.accent

            onAccepted: {
                const entry = clipboardMenu.results[clipboardMenu.selected]
                if (entry)
                    clipboardMenu.copy(entry)
            }
            Keys.onUpPressed: clipboardMenu.selected = Math.max(clipboardMenu.selected - 1, 0)
            Keys.onDownPressed: clipboardMenu.selected = Math.min(clipboardMenu.selected + 1, clipboardMenu.results.length - 1)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: searchInput.text === ""
                text: "Search clipboard"
                font.pixelSize: Theme.fontSize
                color: Theme.dimTextColor
            }
        }
    }

    Text {
        visible: clipboardMenu.results.length === 0
        text: clipboardMenu.entries.length === 0 ? "Clipboard history is empty" : "No matches"
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
    }

    // Scrolls once the list is taller than this
    Flickable {
        id: list
        visible: clipboardMenu.results.length > 0
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: Math.min(rows.implicitHeight, 400)
        contentHeight: rows.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // Scroll so row `index` is on screen, for keyboard navigation
        function ensureVisible(index) {
            for (let i = 0; i < rows.children.length; i++) {
                const row = rows.children[i]
                if (row.index !== index)
                    continue
                if (row.y < contentY)
                    contentY = row.y
                else if (row.y + row.height > contentY + height)
                    contentY = row.y + row.height - height
                return
            }
        }

        Column {
            id: rows
            width: list.width
            spacing: 2

            Repeater {
                model: clipboardMenu.results

                Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: rows.width
                    height: modelData.image ? 48 : 32
                    radius: 8
                    // Only while Enter would copy it
                    color: index === clipboardMenu.selected && searchInput.activeFocus ? Theme.highlight : "transparent"

                    // Thumbnail, decoded on first sight and cached in thumbDir
                    readonly property string thumbPath: clipboardMenu.thumbDir + "/" + modelData.id
                    property bool thumbReady: false

                    Process {
                        running: row.modelData.image
                        command: ["sh", "-c", "mkdir -p \"$3\" && { test -s \"$2\" || cliphist decode \"$1\" > \"$2\"; }",
                            "_", row.modelData.id, row.thumbPath, clipboardMenu.thumbDir]
                        onExited: code => row.thumbReady = code === 0
                    }

                    Image {
                        id: thumb
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.modelData.image
                        width: 64
                        height: 40
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignLeft
                        // Decoded small; the originals can be large screenshots
                        sourceSize: Qt.size(128, 80)
                        asynchronous: true
                        source: row.thumbReady ? "file://" + row.thumbPath : ""
                    }

                    // Placeholder until the thumbnail is ready
                    Text {
                        id: imageIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.modelData.image && thumb.status !== Image.Ready
                        text: "" // image
                        font.family: Theme.iconFont
                        font.weight: Font.Black
                        font.pixelSize: Theme.iconSize
                        color: Theme.dimTextColor
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: row.modelData.image ? 8 + thumb.width + 10 : 10
                        anchors.right: deleteButton.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: Theme.textOffset
                        text: row.modelData.label
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSize
                        color: Theme.textColor
                    }

                    // Delete, shown while hovering the row
                    Rectangle {
                        id: deleteButton
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: rowHover.hovered
                        width: 20
                        height: 20
                        radius: width / 2
                        color: deleteHover.hovered ? Theme.surface : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "" // xmark
                            font.family: Theme.iconFont
                            font.weight: Font.Black
                            font.pixelSize: Theme.iconSize - 2
                            color: Theme.dimTextColor
                        }

                        HoverHandler { id: deleteHover }
                        TapHandler { onTapped: clipboardMenu.remove(row.modelData) }
                    }

                    HoverHandler {
                        id: rowHover
                        onHoveredChanged: {
                            if (hovered)
                                clipboardMenu.selected = row.index
                        }
                    }
                    TapHandler { onTapped: clipboardMenu.copy(row.modelData) }
                }
            }
        }
    }
}
