{ lib, pkgs, config, inputs, ... }:

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

  programs.kitty = {
    enable = true;

    font.package = pkgs.inconsolata;
    font.name = "Inconsolata-Regular";
    font.size = 12;

    # Keep the block cursor; the shell integration otherwise switches it to a beam at the prompt.
    shellIntegration.mode = "no-rc no-cursor";
  };

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
     ;; vc runs git on every file open, and a repo's own .git/config can name
     ;; an fsmonitor program for git to run. Config from the environment
     ;; overrides the repo's, so turn it off for every git Emacs starts.
     (setenv "GIT_CONFIG_COUNT" "1")
     (setenv "GIT_CONFIG_KEY_0" "core.fsmonitor")
     (setenv "GIT_CONFIG_VALUE_0" "false")
    '';
  };

  # Clipboard history, shown by the bar's clipboard menu. Kept in the runtime
  # dir (tmpfs, wiped at logout) rather than ~/.cache; %t is systemd's
  # XDG_RUNTIME_DIR specifier. The menu passes the same path (ClipboardMenu.qml).
  services.cliphist = {
    enable = true;
    extraOptions = [ "-db-path" "%t/cliphist/db" "-max-dedupe-search" "10" "-max-items" "500" ];
  };
  services.hyprpolkitagent.enable = true;

  services.hyprsunset.enable = true;

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
    # Prints the current location as "<lat> <lon>" for the bar's weather
    # widget. Wraps GeoClue's where-am-i demo, which isn't on PATH and keeps
    # reporting fixes until its timeout: prints the first fix and stops it, or
    # prints nothing if there's no fix within the timeout. Rounded to two
    # decimals (about 1 km): enough for a forecast, and the coordinates are
    # sent to Open-Meteo.
    (pkgs.writeShellScriptBin "where-am-i" ''
      exec 3< <(${pkgs.geoclue2}/libexec/geoclue-2.0/demos/where-am-i -t 30 2>/dev/null)
      ${pkgs.gawk}/bin/awk '/^Latitude:/ { lat = $2 + 0 } /^Longitude:/ { printf "%.2f %.2f\n", lat, $2 + 0; exit }' <&3
      kill $! 2>/dev/null
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

  # Tailscale's tray applet. Started after the bar, whose tray it registers
  # with; the daemon has isaiah set as operator so it can control it.
  systemd.user.services.tailscale-systray = {
    Unit = {
      Description = "Tailscale system tray";
      After = [ "graphical-session.target" "quickshell.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.tailscale} systray";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.vscode = {
    enable = true;
    package = unstable.vscode.override {
      commandLineArgs = "--password-store=gnome-libsecret";
    };
  };
}
