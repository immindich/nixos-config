# Test VM for trying out config changes without activating them on the
# laptop. Everything here is scoped to `virtualisation.vmVariant`, so the
# host's toplevel is unchanged; only `system.build.vm` sees it.
#
#   nixos-rebuild build-vm --flake .#laptop     # no root needed
#   ./result/bin/run-laptop-vm-vm
#
# The guest mounts the host's Nix store read-only (the qemu-vm default), so
# nothing is copied. Its own state (home, store overlay) lives in a qcow2
# under ~/.cache/nixos-vm. The checkout is shared in at ~/nixos-config so the
# bar's out-of-store symlink resolves; set NIXOS_CONFIG_SRC to share a
# different worktree. See CLAUDE.md for the workflow.
{ config, lib, pkgs, ... }:

{
  virtualisation.vmVariant = { config, lib, pkgs, ... }: {
    virtualisation = {
      memorySize = 8192;
      cores = 4;
      diskSize = 20 * 1024;
      diskImage = "$HOME/.cache/nixos-vm/laptop.qcow2";

      # virtio-gpu with virgl so Hyprland and Qt get GL. Two heads, so
      # multi-monitor and hotplug behaviour can be tested (see the vm-test
      # skill); each is a tab of the GTK window. The GTK display is an
      # ordinary host window; zoom-to-fit scales the guest's fixed mode (set
      # below) into it instead of resizing the guest to the window.
      qemu.options = [
        "-device virtio-vga-gl,max_outputs=2"
        "-display gtk,gl=on,zoom-to-fit=on"
      ];

      # Bigger 9p packets: the guest reads the whole system and the shell's
      # QML through 9p, and the 16 KiB default costs a round trip per 16 KiB
      msize = 512 * 1024;

      sharedDirectories.nixos-config = {
        source = "\${NIXOS_CONFIG_SRC:-$HOME/nixos-config}";
        target = "/home/isaiah/nixos-config";
      };
      # Never let the guest write to the checkout
      fileSystems."/home/isaiah/nixos-config".options = [ "ro" ];

      forwardPorts = [
        { from = "host"; host.port = 2222; guest.port = 22; }
      ];
    };

    networking.hostName = lib.mkVMOverride "laptop-vm";

    # Same aspect ratio and scale as the laptop panel (2880x1800 @ 2), so
    # the bar renders at the same pixel sizes as on the host. Without a fixed
    # mode the guest follows the QEMU window's size at scale 1.
    home-manager.users.isaiah.wayland.windowManager.hyprland.settings.monitor = {
      mode = lib.mkVMOverride "1920x1200@60";
      scale = lib.mkVMOverride 2;
    };

    # Boot straight into the Hyprland session as isaiah
    services.greetd = {
      enable = true;
      settings = let
        session = {
          command = lib.getExe config.programs.hyprland.package;
          user = "isaiah";
        };
      in {
        initial_session = session;
        default_session = session;
      };
    };

    services.openssh.enable = true;
    users.users.isaiah = {
      initialPassword = "isaiah";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKocrW5NT475m9LhsoXS/Oj85m6kB4hWDBpIArTriDwf nixos-vm"
      ];
      extraGroups = [ config.programs.ydotool.group ];
    };

    # Input injection for testing the shell over ssh (see CLAUDE.md):
    # ydotool moves and clicks the pointer through uinput, wtype types into
    # the focused window. No pointer acceleration, so ydotool's moves land
    # where they're told to.
    programs.ydotool.enable = true;
    environment.systemPackages = [ pkgs.wtype ];
    home-manager.users.isaiah.wayland.windowManager.hyprland.settings.config.input.accel_profile =
      lib.mkVMOverride "flat";

    # Laptop hardware and services that don't exist or don't make sense in
    # the guest
    services.fprintd.enable = lib.mkVMOverride false;
    services.tailscale.enable = lib.mkVMOverride false;
    services.fwupd.enable = lib.mkVMOverride false;
    hardware.bluetooth.enable = lib.mkVMOverride false;
    # No tailscaled to talk to; without this the tray applet restart-loops
    home-manager.users.isaiah.systemd.user.services.tailscale-systray.Install.WantedBy =
      lib.mkVMOverride [ ];

    # Session services that compete with Quickshell's startup and aren't
    # exercised in the guest: the desktop portals (which Flatpak insists on,
    # so it goes too) and the ScreenSaver inhibit bridge
    services.flatpak.enable = lib.mkVMOverride false;
    xdg.portal.enable = lib.mkVMOverride false;
    home-manager.users.isaiah.systemd.user.services.screensaver-inhibit.Install.WantedBy =
      lib.mkVMOverride [ ];
  };
}
