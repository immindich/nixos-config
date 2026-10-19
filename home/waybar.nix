{ config, ... }:

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

      network = {
        format = "{icon}";
        # Left click toggles showing the Wi-Fi network name
        format-alt = "{icon} {essid}";
        format-icons = {
          wifi = "";
          ethernet = "";
          disconnected = "";
        };
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = " muted";
        format-icons.default = [ "" "" "" ];
      };
    };

    # The default stylesheet asks for "FontAwesome", which doesn't match Font
    # Awesome 7, so icons fell back to corefonts (blank volume icons). Put a text
    # font first since Font Awesome also has digit glyphs.
    style = ''
      @import "${config.programs.waybar.package}/etc/xdg/waybar/style.css";

      * {
        font-family: "DejaVu Sans", "Font Awesome 7 Free Solid", sans-serif;
      }
    '';
  };
}
