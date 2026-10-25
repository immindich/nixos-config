//@ pragma IconTheme Papirus-Dark
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.menus

ShellRoot {
  // One wallpaper per screen
  Variants {
    model: Quickshell.screens
    delegate: Wallpaper {}
  }

  // One bar per screen
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
        // Reserve space only down to the bubbles; Hyprland's gaps_out supplies
        // the gap below them, so it matches the gaps between windows
        exclusiveZone: Theme.barHeight - Theme.barMargin
        color: "transparent"

        // NixOS logo; opens the lock/sleep/shut down/exit menu
        Rectangle {
          id: session
          anchors.left: parent.left
          anchors.leftMargin: Theme.barMargin
          anchors.verticalCenter: parent.verticalCenter
          implicitWidth: sessionButton.width + 8
          implicitHeight: Theme.bubbleHeight
          radius: height / 2
          color: Theme.background

          Rectangle {
            id: sessionButton
            anchors.centerIn: parent
            width: Theme.workspaceSize
            height: Theme.workspaceSize
            radius: height / 2
            color: sessionMenu.visible ? Theme.highlight : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.animationDuration } }

            // The white logo, recolored to match the other bar icons
            IconImage {
              id: logo
              anchors.centerIn: parent
              implicitSize: 14
              source: Quickshell.iconPath("nix-snowflake-white")
              layer.enabled: true
              layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: Theme.textColor
              }
            }

            TapHandler { onTapped: sessionMenu.toggle() }

            SessionMenu {
              id: sessionMenu
              anchor.item: sessionButton
            }
          }
        }

        WorkspaceSwitcher {
          id: workspaces
          anchors.left: session.right
          anchors.leftMargin: Theme.bubbleSpacing
        }

        // Centered on the bar, so it can extend half its width either side of
        // the center; limit that to the room before the nearest neighbor
        WindowTitle {
          anchors.centerIn: parent
          maxWidth: {
            const center = parent.width / 2
            const leftRoom = center - (workspaces.x + workspaces.width)
            const rightRoom = (tray.visible ? tray.x : statusArea.x) - center
            return Math.min(600, 2 * (Math.min(leftRoom, rightRoom) - Theme.bubbleSpacing))
          }
        }

        TrayArea {
          id: tray
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

  // One popup stack, on the focused screen
  NotificationPopups {}

  // Volume/brightness OSD, on the focused screen
  Osd {}

  // ALT+Tab window switcher, on the focused screen
  WindowSwitcher {}
}
