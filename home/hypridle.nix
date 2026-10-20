{ ... }:

{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        # Lock before suspend; hypridle holds off sleep until hyprlock has
        # locked the session (inhibit_sleep's default "auto" behavior)
        before_sleep_cmd = "loginctl lock-session";
        lock_cmd = "pidof hyprlock || hyprlock";
      };
    };
  };
}
