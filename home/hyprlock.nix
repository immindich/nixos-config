{ ... }:

{
  programs.hyprlock = {
    enable = true;
    # Installed by programs.hyprlock in the NixOS config (which also sets up PAM)
    package = null;

    settings = {
      # Uses fprintd over D-Bus, in parallel with the password field
      auth = {
        fingerprint.enabled = true;
      };

      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = [
        {
          monitor = "";
          path = "screenshot";
          blur_passes = 3;
          blur_size = 7;
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_size = 64;
          color = "rgba(ddddddff)";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "250, 50";
          outline_thickness = 2;
          # Same gradient as the active window border
          outer_color = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          inner_color = "rgba(1a1a1aee)";
          font_color = "rgb(dddddd)";
          fade_on_empty = false;
          placeholder_text = "Password";
          position = "0, -40";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
