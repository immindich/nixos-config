import Quickshell
import Quickshell.Io
import QtQuick

Variants {
  model: Quickshell.screens;

  delegate: Component {
    PanelWindow {
      // the screen from the screens list will be injected into this
      // property
      required property var modelData

      // we can then set the window's screen to the injected property
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: Theme.barHeight
      color: "transparent"

      WorkspaceSwitcher {
        anchors.left: parent.left
        anchors.leftMargin: Theme.barMargin
      }

      WindowTitle {
        anchors.centerIn: parent
      }

      TrayArea {
        anchors.right: statusArea.left
        anchors.rightMargin: Theme.bubbleSpacing
      }

      StatusArea {
        id: statusArea
        anchors.right: parent.right
        anchors.rightMargin: Theme.barMargin
      }

      // Close the open menu on any press on the bar, except on the indicator
      // that owns it (which toggles it itself). The press still reaches
      // whatever is underneath.
      MouseArea {
        id: closeMenus
        anchors.fill: parent
        onPressed: mouse => {
          const menu = MenuState.openMenu
          if (menu) {
            const item = menu.anchor.item
            if (!item.contains(item.mapFromItem(closeMenus, mouse.x, mouse.y)))
              menu.visible = false
          }
          mouse.accepted = false
        }
      }
    }
  }
}