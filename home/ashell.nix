{ inputs, pkgs, ... }:

{
  programs.ashell = {
    enable = true;
    # 26.05's ashell (0.8.0) shows duplicate tray icons; use unstable's
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.ashell;
    # For a more compact tray menu (smaller item padding and gaps), build a
    # patched ashell instead (compiles from source):
    # package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.ashell.overrideAttrs (old: {
    #   patches = (old.patches or [ ]) ++ [ ./ashell-compact-tray-menu.patch ];
    # });
    # Started with the Hyprland session via graphical-session.target
    systemd.enable = true;

    settings = {
      modules = {
        left = [ "Workspaces" ];
        center = [ "WindowTitle" ];
        right = [ "Tray" [ "Tempo" "Privacy" "Settings" ] ];
      };

      # Always show workspaces 1-5, even when empty; 6-10 appear while occupied
      workspaces = {
        enable_workspace_filling = true;
        max_workspaces = 5;
      };

      # Volume, brightness, network, battery shown in the bar; Settings opens
      # the quick-settings panel
      settings = {
        indicators = [ "Audio" "Brightness" "Network" "Battery" ];
        audio_indicator_format = "IconAndPercentage";
        brightness_indicator_format = "IconAndPercentage";
      };
    };
  };
}
