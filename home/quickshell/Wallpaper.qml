import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Full-screen picture on the background layer, below all windows. Falls back
// to the theme background if the file is missing. Reloads when the file
// changes on disk.
PanelWindow {
  required property var modelData
  screen: modelData

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // Cover the whole screen, ignoring the bar's reserved space
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.namespace: "quickshell-wallpaper"

  color: Theme.background

  Image {
    id: image
    anchors.fill: parent
    source: "file://" + Theme.wallpaper
    // Otherwise reloading the same path would reuse the old picture
    cache: false
    fillMode: Image.PreserveAspectCrop
    // Decode at the screen's physical resolution rather than the file's
    sourceSize.width: width * (modelData.devicePixelRatio || 1)
    sourceSize.height: height * (modelData.devicePixelRatio || 1)
    asynchronous: true
  }

  // Dim the top of the picture (usually bright sky), fading out by the middle
  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.wallpaperDim) }
      GradientStop { position: 0.3; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.wallpaperDim) }
      GradientStop { position: 0.55; color: "transparent" }
    }
  }

  FileView {
    path: Theme.wallpaper
    watchChanges: true
    // Only watch it; the Image does the loading
    preload: false
    printErrors: false
    onFileChanged: {
      image.source = ""
      image.source = "file://" + Theme.wallpaper
    }
  }
}
