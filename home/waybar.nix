{ ... }:

{
  programs.waybar = {
    enable = true;
    # Started with the Hyprland session via graphical-session.target
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "hyprland/window" ];
      modules-right = [ "pulseaudio" "network" "battery" "clock" "tray" ];

      # Icons are Font Awesome glyphs (font-awesome is in fonts.packages)
      battery = {
        format = "{icon} {capacity}%";
        format-charging = " {capacity}%";
        format-plugged = " {capacity}%";
        format-icons = [ "" "" "" "" "" ];
      };

      # Always show workspaces 1-5, even when empty; 6-10 appear while occupied
      "hyprland/workspaces" = {
        persistent-workspaces."*" = 5;
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = " muted";
        format-icons.default = [ "" "" "" ];
      };
    };
  };
}
