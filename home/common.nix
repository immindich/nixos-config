{ pkgs, ... }:

{
  imports = [ ./hyprland.nix ./waybar.nix ];

  home.username = "isaiah";
  home.homeDirectory = "/home/isaiah";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.bash.enable = true;

  programs.foot.enable = true;

  home.sessionPath = [ "$HOME/.local/bin" ];
}