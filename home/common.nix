{ pkgs, config, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in {
  imports = [ ./hyprland.nix ./hyprlock.nix ./hypridle.nix ];

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
  services.hyprpolkitagent.enable = true;

  home.sessionPath = [ "$HOME/.local/bin" ];

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  gtk.enable = true;
  gtk.theme.name = "Adwaita-dark";
  gtk.theme.package = pkgs.gnome-themes-extra;

  # Qt apps: KDE's platform theme with the Breeze style
  qt.enable = true;
  qt.platformTheme.name = "kde";
  qt.platformTheme.package = pkgs.kdePackages.plasma-integration;
  qt.style.name = "breeze";
  qt.style.package = pkgs.kdePackages.breeze;

  home.packages = [
    # Icon theme for the bar's app icons; selected in shell.qml
    pkgs.papirus-icon-theme
    # Breeze Dark colours as a system-wide kdeglobals. KDE apps merge it under
    # ~/.config/kdeglobals, which stays writable for their own settings.
    (pkgs.runCommand "breeze-dark-kdeglobals" { } ''
      mkdir -p $out/etc/xdg
      ln -s ${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors $out/etc/xdg/kdeglobals
    '')
  ];

  dconf.settings."org/gnome/desktop/interface".font-name = "Cantarell 9";

  xdg.configFile."quickshell".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/home/quickshell";

  # The bar. Started with the Hyprland session via graphical-session.target;
  # uses the config linked above (no `configs`, so it doesn't conflict)
  programs.quickshell = {
    enable = true;
    systemd.enable = true;
  };

  programs.vscode = {
    enable = true;
    package = unstable.vscode.override {
      commandLineArgs = "--password-store=gnome-libsecret";
    };
  };
}
