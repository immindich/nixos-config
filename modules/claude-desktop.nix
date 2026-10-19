{ inputs, pkgs, ... }:
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
}
