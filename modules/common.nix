{ pkgs, inputs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.configurationLimit = 5;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  networking.networkmanager.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # Battery info for the ashell bar
  services.upower.enable = true;

  services.geoclue2.enable = true;

  environment.systemPackages = with pkgs; [
    jq
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
    (texliveBasic.withPackages (ps: with ps; [
      latexmk amsmath mathtools thmtools enumitem cleveref
      pgf tikz-cd xcolor microtype booktabs caption
      biblatex biber csquotes jknapltx rsfs stmaryrd cm-super
    ]))
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
    sox
    kdePackages.dolphin
    kdePackages.gwenview
    umu-launcher
    mpv
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
    corefonts
  ];

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  programs.dconf.enable = true;

  services.libinput.enable = true;

  services.tailscale.enable = true;

  services.fwupd.enable = true;

  programs.steam.enable = true;

  services.flatpak.enable = true;

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;
  programs.firefox.enable = true;
  # Open the camera through PipeWire instead of /dev/video directly, so the
  # bar's privacy indicator can see it
  programs.firefox.preferences."media.webrtc.camera.allow-pipewire" = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib   # libstdc++, libgcc_s
      zlib
      openssl
    ];
  };

  environment.localBinInPath = true;

  # NixOS's default prompt without its leading blank line. Instead, as zsh's
  # PROMPT_SP does, print "%" and pad to the line's end before each prompt: on
  # an empty line the prompt overwrites it, and after output with no trailing
  # newline the padding wraps, leaving the "%" as a marker and the prompt on a
  # fresh line. The marker is printed from PROMPT_COMMAND rather than PS1:
  # readline reprints the prompt when it redraws a wrapped line, and the
  # padding would then blank out the line being edited.
  programs.bash.promptInit = ''
    if [ "$TERM" != "dumb" ] || [ -n "$INSIDE_EMACS" ]; then
      PROMPT_COLOR="1;31m"
      ((UID)) && PROMPT_COLOR="1;32m"
      PROMPT_COMMAND+=('printf "%%%*s\r" $((COLUMNS-1)) ""')
      if [ -n "$INSIDE_EMACS" ]; then
        # Emacs term mode doesn't support xterm title escape sequence (\e]0;)
        PS1="\[\033[$PROMPT_COLOR\][\u@\h:\w]\\$\[\033[0m\] "
      else
        PS1="\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\[\033[0m\] "
      fi
      if test "$TERM" = "xterm"; then
        PS1="\[\033]2;\h:\u:\w\007\]$PS1"
      fi
    fi
  '';
}
