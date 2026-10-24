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
        # screensaver-inhibit (below) answers org.freedesktop.ScreenSaver
        # instead, so those inhibits show up in logind's list
        ignore_dbus_inhibit = true;
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

  # Takes a logind idle inhibitor for each org.freedesktop.ScreenSaver
  # inhibit (Firefox, video players), so the bar's power menu can list them
  # with the app and reason. hypridle honors those like its own.
  systemd.user.services.screensaver-inhibit = {
    Unit = {
      Description = "org.freedesktop.ScreenSaver inhibits as logind inhibitors";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.ScreenSaver";
      ExecStart = "${pkgs.python3.withPackages (ps: [ ps.pygobject3 ])}/bin/python3 ${./screensaver-inhibit.py}";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
