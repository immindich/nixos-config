{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  networking.networkmanager.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # Battery info for the ashell bar
  services.upower.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    kitty
    brightnessctl
    nvd
    bluetui
    wl-clipboard
    quickshell
    grim
    slurp
    lf
    python3
    pavucontrol
    htop
    acpi
    acpilight
    ncdu
    screenfetch
    powertop
    efibootmgr
    pciutils
    usbutils
    smartmontools
    unzip
    lm_sensors
    lzip
    restic
    intel-gpu-tools
    ffmpeg-full
    tmux
    tor-browser
    chromium
    networkmanagerapplet
    sysstat
    kdePackages.okular
    sl
    texliveMedium
    yt-dlp
    dosbox
    transmission_4-qt6
    imagemagick
    p7zip
    unrar
    jellyfin-desktop
    xeyes
    wineWow64Packages.stable
    signal-desktop
    nix-tree
    file
  ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
    #keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
    packages = with pkgs; [ terminus_font ];
  };

  services.xserver.xkb.options = "ctrl:nocaps";

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    liberation_ttf
    font-awesome
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    google-fonts
    corefonts
  ];

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  programs.dconf.enable = true;

  services.libinput.enable = true;

  services.tailscale.enable = true;

  services.fwupd.enable = true;

  programs.steam.enable = true;

  programs.kdeconnect.enable = true;

  services.flatpak.enable = true;

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;
  programs.firefox.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib   # libstdc++, libgcc_s
      zlib
      openssl
    ];
  };

  environment.localBinInPath = true;
}
