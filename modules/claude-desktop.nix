{ config, inputs, pkgs, ... }:
{
  imports = [ inputs.claude-desktop.nixosModules.default ];
  nixpkgs.overlays = [ inputs.claude-desktop.overlays.default ];

  programs.claude-desktop = {
    enable = true;
    # Electron only picks the libsecret backend for desktops it recognises;
    # under Hyprland its safeStorage falls back to basic_text, so OAuth tokens
    # and the device key don't persist and the app keeps asking to sign in.
    package = (pkgs.claude-desktop.override {
      libpipewire = pkgs.pipewire;
      qemu-cowork = pkgs.qemu_kvm;
    }).overrideAttrs (old: {
      postFixup = old.postFixup + ''
        wrapProgramShell "$out/bin/claude-desktop" \
          --add-flags "--password-store=gnome-libsecret"
      '';
    });
    cowork = {
      enable = true;
      users = [ "isaiah" ];
    };
  };

  # The app runs these from hardcoded /usr/bin paths instead of PATH:
  # busctl to probe for the GlobalShortcuts portal (the quick entry hotkey),
  # and QEMU, which Cowork requires there since 4.29.0.
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/busctl - - - - ${config.systemd.package}/bin/busctl"
    "L+ /usr/bin/qemu-system-x86_64 - - - - ${config.programs.claude-desktop.package.qemu-cowork}/bin/qemu-system-x86_64"
  ];
}
