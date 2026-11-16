# Fingerprint unlock in hyprlock, and nowhere else.
{ lib, pkgs, ... }:

{
  imports = [
    # Turn off fingerprint PAM auth for every service (see fprintd below)
    {
      options.security.pam.services = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          config.fprintAuth = lib.mkDefault false;
        });
      };
    }
  ];

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
}
