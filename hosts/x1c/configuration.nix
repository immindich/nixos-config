# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let libcamera_0_8 = pkgs.libcamera.overrideAttrs (old: rec {
      version = "0.8.0";
      src = pkgs.fetchgit {
        url = "https://gitlab.freedesktop.org/camera/libcamera.git/";
        rev = "v${version}";
        hash = "sha256-HPQZEzxH1QqmNpMVvKeYl2o7rxfNNP+npCyzYHYyFP8=";
      };
      buildInputs = old.buildInputs ++ (with pkgs; [
        libjpeg
        libyuv
        elfutils
        libGL
        libtiff
        SDL2
      ]);
      patches = (old.patches or []) ++ [
        # imx471 exposure and gain both latch 2 frames late (measured).
        ./libcamera-imx471-sensor-delays.patch
        # Without this the software ISP drops the sensor to 1x gain for a
        # frame at startup (a dark flash) and lags AGC by an iteration.
        ./libcamera-softisp-send-latest-agc.patch
      ];
      postInstall = (old.postInstall or "") + ''
        install -Dm644 ${./imx471.yaml} $out/share/libcamera/ipa/softisp/imx471.yaml
      '';
    });
    pipewire' = (pkgs.pipewire.override { libcamera = libcamera_0_8; }).overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        # spa: libcamera: source: use `std::span`
        (pkgs.fetchpatch {
          url = "https://gitlab.freedesktop.org/pipewire/pipewire/-/commit/7bc41112e8453c482fb7a408af7928ba5cc68a94.patch";
          hash = "sha256-7lSn3U18Uw36nYdDYlQX/oF8EecktOXIzK4FJITvWDs=";
        })
        # spa: libcamera: device: 0.8 compatibility
        (pkgs.fetchpatch {
          url = "https://gitlab.freedesktop.org/pipewire/pipewire/-/commit/54f2f51f5233026e608f8235f5377b9b473918e3.patch";
          hash = "sha256-eIS9n5K2wTz++7Nf6tzWah61EA/73soS1vIG/n7UUqY=";
        })
      ];
      # The version check above needs LIBCAMERA_VERSION_*; upstream gets it
      # from a later commit (44176d411) that 1.6.6 doesn't have.
      postPatch = (old.postPatch or "") + ''
        sed -i '1i #include <libcamera/version.h>' spa/plugins/libcamera/libcamera-device.cpp
      '';
    });
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/battery.nix
      ../../modules/fingerprint.nix
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelPatches = [
    {
      name = "imx471-crop-fix";
      patch = ./0001-media-i2c-imx471-Fix-V4L2_SEL_TGT_CROP-returning-EIN.patch;
    }
    {
      name = "imx471-gain-960";
      patch = ./0003-media-i2c-imx471-Raise-the-analogue-gain-limit-to-th.patch;
    }
  ];

  assertions = [{
    assertion = lib.versionOlder config.boot.kernelPackages.kernel.version "7.4";
    message = "Kernel updated to 7.4, check camera patches.";
  }];

  boot.initrd.luks.devices.cryptlvm = {
    device = "/dev/disk/by-uuid/5e1d32f4-0a2d-404a-8707-3b2067b056bb";
    allowDiscards = true;
  };

  fileSystems."/".options = [ "noatime" "nodiratime" ];

  hardware.cpu.intel.updateMicrocode = true;

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
  ];

  networking.hostName = "x1c";

  services.pipewire.package = pipewire';
  services.pipewire.wireplumber.package = pkgs.wireplumber.override { pipewire = pipewire'; };

  # The libcamera source stops the camera when PipeWire takes back its buffers
  # and format after the last stream disconnects, but the node stays marked
  # running, so a stream that reconnects quickly gets a Start that does
  # nothing and never sees a frame (Cheese, toggling video in Meet). Pausing
  # the node when it goes idle keeps PipeWire's state in step with the camera.
  services.pipewire.wireplumber.extraConfig."50-libcamera-pause-on-idle" = {
    "monitor.libcamera.rules" = [{
      matches = [{ "node.name" = "~libcamera_input.*"; }];
      actions.update-props."node.pause-on-idle" = true;
    }];
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
