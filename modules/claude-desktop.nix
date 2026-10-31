{ config, inputs, pkgs, ... }:
{
  imports = [ inputs.claude-desktop.nixosModules.default ];
  nixpkgs.overlays = [ inputs.claude-desktop.overlays.default ];

  programs.claude-desktop = {
    enable = true;
    package = pkgs.claude-desktop.override {
      libpipewire = pkgs.pipewire;
      qemu-cowork = pkgs.qemu_kvm;
    };
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
