# Battery and power settings for ThinkPad laptops. The charge thresholds
# need thinkpad_acpi's charge_control_* files on BAT0.
{ pkgs, ... }:

{
  services.power-profiles-daemon.enable = true;
  services.udev.extraRules = ''
    # power-profiles-daemon keeps whatever profile was last chosen and only
    # drops to power-saver once upower reports the battery as low (under 20
    # minutes left), so follow the charger ourselves: power-saver on battery,
    # balanced on AC. "change" only: at boot's "add" D-Bus isn't up yet, and
    # the daemon restores its saved profile anyway.
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced"
  '';

  # Stop charging at 80% and don't top up again until 75%, to spare the
  # battery. The embedded controller enforces these and keeps them across
  # reboots, but loses them if it's reset, so set them at every boot. Not a
  # udev rule on BAT0's "add": thinkpad_acpi adds the threshold files about a
  # second after the battery appears, so the rule's writes failed silently.
  systemd.services.battery-charge-thresholds = {
    description = "Set battery charge thresholds";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      bat=/sys/class/power_supply/BAT0
      for _ in $(seq 100); do
        [ -e $bat/charge_control_start_threshold ] && break
        sleep 0.1
      done
      echo 80 > $bat/charge_control_end_threshold
      echo 75 > $bat/charge_control_start_threshold
    '';
  };
}
