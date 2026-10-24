import QtQuick
import qs

// Opened from the sound indicator, with two tabs like KDE's: Devices (output
// and input selection with volume and mute) and Applications (a volume
// control per playing program). Opens on Devices. Set `anchor.item` to the
// indicator.
DropdownMenu {
    id: audioMenu

    // 0: Devices, 1: Applications
    property int tab: 0

    // Wider than the default to leave room for longer device names
    implicitWidth: 320

    onVisibleChanged: if (visible) tab = 0

    Row {
        id: tabs
        width: parent.width - parent.leftPadding - parent.rightPadding
        spacing: 4

        Repeater {
            model: ["Devices", "Applications"]

            Rectangle {
                id: tabButton
                required property string modelData
                required property int index
                readonly property bool selected: audioMenu.tab === index

                width: (tabs.width - tabs.spacing) / 2
                height: 28
                radius: 8
                color: selected ? Theme.accent : hover.hovered ? Theme.highlight : Theme.surface

                Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Theme.textOffset
                    text: tabButton.modelData
                    font.pixelSize: Theme.fontSize
                    color: tabButton.selected ? Theme.background : Theme.textColor
                }

                HoverHandler { id: hover }
                TapHandler { onTapped: audioMenu.tab = tabButton.index }
            }
        }
    }

    AudioDeviceSection { visible: audioMenu.tab === 0; title: "Output"; sink: true }
    Item { visible: audioMenu.tab === 0; width: 1; height: 4 }
    AudioDeviceSection { visible: audioMenu.tab === 0; title: "Input"; sink: false }

    AudioStreamSection { visible: audioMenu.tab === 1 }
}
