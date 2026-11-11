# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Turn off fingerprint PAM auth for every service (see fprintd below)
      {
        options.security.pam.services = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            config.fprintAuth = lib.mkDefault false;
          });
        };
      }
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/ab514cd3-78e1-4ee8-a53d-8585509eaafe";
    allowDiscards = true;
  };

  fileSystems."/".options = [ "noatime" "nodiratime" ];

  hardware.cpu.intel.updateMicrocode = true;

  # Only used by hyprlock, which talks to fprintd directly. fprintAuth
  # defaults to true for every PAM service when fprintd is enabled, and
  # pam_fprintd blocks password entry until the fingerprint times out.
  services.fprintd.enable = true;
  # The sensor comes back from suspend as a new USB device (libfprint turns
  # USB persist off for it), and fprintd doesn't notice when the old one was
  # claimed: every later Claim fails with "already claimed" until fprintd
  # restarts. Stopping it before sleep means hyprlock starts a fresh one
  # over D-Bus after resume, which finds the sensor as it is now.
  powerManagement.powerDownCommands = "systemctl stop fprintd.service";
  # A lock screen already up before the suspend held a claim on the old
  # device; without this it never asks fprintd again after resume, so the
  # fingerprint stays off until the next lock.
  programs.hyprlock.package = pkgs.hyprlock.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./hyprlock-fingerprint-reclaim-after-sleep.patch ];
  });

  services.libinput = {
    enable = true;
    touchpad = {
      tapping = false;
      naturalScrolling = true;
      accelSpeed = "0.5";
      clickMethod = "clickfinger";
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "laptop";

  # Set your time zone.
  time.timeZone = null;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security.tpm2.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.isaiah = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "tss" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

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

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}

