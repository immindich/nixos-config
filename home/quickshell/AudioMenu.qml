import QtQuick

// Output and input device selection with volume and mute, opened from the
// sound indicator. Set `anchor.item` to the indicator.
DropdownMenu {
    // Wider than the default to leave room for longer device names
    implicitWidth: 320

    AudioDeviceSection { title: "Output"; sink: true }
    Item { width: 1; height: 4 }
    AudioDeviceSection { title: "Input"; sink: false }
}
