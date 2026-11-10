import QtQuick
import qs

// Bold section heading for a DropdownMenu. Plain text, since some headings
// are names from other programs (a media player's)
Text {
    textFormat: Text.PlainText
    font.pixelSize: Theme.fontSize
    font.bold: true
    color: Theme.textColor
}
