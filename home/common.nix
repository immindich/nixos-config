{ pkgs, ... }:

{
  imports = [ ./hyprland.nix ./waybar.nix ];

  home.username = "isaiah";
  home.homeDirectory = "/home/isaiah";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.bash.enable = true;

  programs.foot.enable = true;

  # Runs hyprlauncher as a daemon so the launcher opens instantly
  services.hyprlauncher.enable = true;

  home.sessionPath = [ "$HOME/.local/bin" ];

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
}