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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.isaiah = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  services.power-profiles-daemon.enable = true;

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

