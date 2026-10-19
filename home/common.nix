{ pkgs, ... }:

{
  imports = [ ./hyprland.nix ./waybar.nix ];

  home.username = "isaiah";
  home.homeDirectory = "/home/isaiah";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.bash.enable = true;

  programs.foot.enable = true;
  programs.foot.settings.main.font = "monospace:size=9";

  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
    extraPackages = epkgs: [
      epkgs.nix-mode
      epkgs.zenburn-theme
      epkgs.magit
    ];
    extraConfig = ''
     (ido-mode 1)
     (scroll-bar-mode -1)
     (menu-bar-mode -1)
     (tool-bar-mode -1)
     (setq-default indent-tabs-mode nil)
    '';
  };

  # Runs hyprlauncher as a daemon so the launcher opens instantly
  services.hyprlauncher.enable = true;

  home.sessionPath = [ "$HOME/.local/bin" ];

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  gtk.enable = true;
  gtk.theme.name = "Adwaita-dark";
  gtk.theme.package = pkgs.gnome-themes-extra;

  dconf.settings."org/gnome/desktop/interface".font-name = "Cantarell 9";
}
