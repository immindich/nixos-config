import QtQuick
import Quickshell.Bluetooth
import qs

// Media, brightness and night light, and Bluetooth in one menu, opened from
// the control center indicator; set `anchor.item` to it. Each section is
// hidden when there's nothing for it to control (no player, no backlight or
// hyprsunset, no Bluetooth adapter), with a divider between the ones shown.
DropdownMenu {
    id: controlCenter

    menuWidth: Theme.px(320)

    readonly property bool hasMedia: Media.player !== null
    readonly property bool hasBrightness: Brightness.max > 0 || NightLight.available
    readonly property bool hasBluetooth: Bluetooth.defaultAdapter !== null

    component Divider: Rectangle {
        width: parent.width - parent.leftPadding - parent.rightPadding
        height: Theme.px(1)
        color: Theme.borderColor
    }

    MediaSection {
        visible: controlCenter.hasMedia
        shown: controlCenter.visible
    }

    Divider { visible: controlCenter.hasMedia && (controlCenter.hasBrightness || controlCenter.hasBluetooth) }

    BrightnessSection { visible: controlCenter.hasBrightness }

    Divider { visible: controlCenter.hasBrightness && controlCenter.hasBluetooth }

    BluetoothSection { visible: controlCenter.hasBluetooth }

    Text {
        visible: !controlCenter.hasMedia && !controlCenter.hasBrightness && !controlCenter.hasBluetooth
        text: "Nothing to control"
        font.pixelSize: Theme.fontSize
        color: Theme.dimTextColor
    }
}
