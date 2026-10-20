{ lib, pkgs, ... }:

let
  # hypridle's service PATH doesn't include brightnessctl
  brightnessctl = lib.getExe pkgs.brightnessctl;
in

{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        # Lock before suspend; hypridle holds off sleep until hyprlock has
        # locked the session (inhibit_sleep's default "auto" behavior)
        before_sleep_cmd = "loginctl lock-session";
        # Make sure the display comes back after resuming from suspend
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
        lock_cmd = "pidof hyprlock || hyprlock";
      };

      # Skipped while the bar's keep-awake (idle inhibitor) toggle is on
      listener = [
        # 5 min: dim the backlight (-s saves the level, -r restores it)
        {
          timeout = 300;
          on-timeout = "${brightnessctl} -s set 10%";
          on-resume = "${brightnessctl} -r";
        }
        # 10 min: lock
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        # 11 min: turn the display off. Hyprland is in Lua mode, so dpms takes
        # the Lua dispatcher form (an unrecognized action means "toggle")
        {
          timeout = 660;
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
        }
        # 30 min: suspend
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
