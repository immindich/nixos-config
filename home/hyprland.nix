{ lib, pkgs, ... }:
let
  # For the screenshot notification's "Open folder" button
  fileManager = "dolphin";

  # Posts a notification showing the screenshot in $file, with an "Open
  # folder" button that shows it in the file manager and, with `edit`, an
  # "Edit" button that opens it in Satty with the crop tool selected (Enter
  # saves over the file and copies the result; Escape closes; it opens as a
  # floating window, see the satty-float rule). notify-send waits for the
  # button until the notification closes, so this runs in the background. (notify-send's -i
  # also lands in the image-path hint, so there's no separate app icon.)
  # Hyprland tags everything started by exec_cmd with
  # HL_INITIAL_WORKSPACE_TOKEN and opens its first window on the workspace it
  # was started from; clear it so the window opens where you are now.
  screenshotNotify = { edit ? false }: lib.removeSuffix "\n" ''
    (
      case "$(notify-send -a Screenshot -h "string:image-path:$file" \
          -A "folder=Open folder" ${lib.optionalString edit ''-A "edit=Edit" ''}"Screenshot saved" "Copied to the clipboard")" in
        folder) env -u HL_INITIAL_WORKSPACE_TOKEN ${fileManager} --select "$file" ;;
        edit) env -u HL_INITIAL_WORKSPACE_TOKEN ${lib.getExe pkgs.satty} --filename "$file" --output-filename "$file" \
            --initial-tool crop --copy-command wl-copy --actions-on-enter save-to-clipboard,save-to-file,exit \
            --disable-notifications ;;
      esac
    )
  '';

  # Drag to select a region; saves to ~/screenshots, copies to the clipboard
  # and shows a notification. Running it again while a selection is in
  # progress cancels the selection.
  screenshot = pkgs.writeShellApplication {
    name = "screenshot-region";
    runtimeInputs = [ pkgs.grim pkgs.slurp pkgs.wl-clipboard pkgs.util-linux pkgs.libnotify ];
    text = ''
      pidfile="$XDG_RUNTIME_DIR/screenshot-region.pid"
      exec 9>"$XDG_RUNTIME_DIR/screenshot-region.lock"
      if ! flock -n 9; then
        pid=$(cat "$pidfile" 2>/dev/null) || exit 0
        kill "$pid" 2>/dev/null || true
        exit 0
      fi
      dir="$HOME/screenshots"
      mkdir -p "$dir"
      file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
      region=$(slurp & echo $! > "$pidfile"; wait $!) || { rm -f "$pidfile"; exit 0; }
      rm -f "$pidfile"
      grim -g "$region" "$file"
      # wl-copy stays running to serve the clipboard, and the notification
      # waits for its button; don't let either hold the lock
      wl-copy --type image/png < "$file" 9>&-
      ${screenshotNotify { edit = true; }} 9>&- &
    '';
  };

  # Capture the focused window via the compositor (works even if it's partly
  # covered); saves to ~/screenshots, copies to the clipboard, plays a sound
  # and shows a notification.
  screenshotWindow = pkgs.writeShellApplication {
    name = "screenshot-window";
    runtimeInputs = [ pkgs.grim pkgs.jq pkgs.wl-clipboard pkgs.pipewire pkgs.libnotify ];
    text = ''
      id=$(hyprctl activewindow -j | jq -r '.stableId // empty')
      [ -n "$id" ] || exit 0
      dir="$HOME/screenshots"
      mkdir -p "$dir"
      file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
      grim -T "$id" "$file"
      pw-play ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/screen-capture.oga &
      wl-copy --type image/png < "$file"
      ${screenshotNotify { }} &
    '';
  };

  # Capture the focused monitor; saves to ~/screenshots, copies to the
  # clipboard, plays a sound and shows a notification whose Edit button
  # opens the shot in Satty for cropping.
  screenshotScreen = pkgs.writeShellApplication {
    name = "screenshot-screen";
    runtimeInputs = [ pkgs.grim pkgs.jq pkgs.wl-clipboard pkgs.pipewire pkgs.libnotify ];
    text = ''
      output=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
      [ -n "$output" ] || exit 0
      dir="$HOME/screenshots"
      mkdir -p "$dir"
      file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
      grim -o "$output" "$file"
      pw-play ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/screen-capture.oga &
      wl-copy --type image/png < "$file"
      ${screenshotNotify { edit = true; }} &
    '';
  };

  # Steps the backlight by 5% of full brightness up or down, the same scale
  # the bar's OSD and slider show, never quite to off (-n2: a raw minimum of
  # 2). Used by the brightness keys and by scrolling on the bar's control
  # center indicator.
  brightnessStep = pkgs.writeShellApplication {
    name = "brightness-step";
    runtimeInputs = [ pkgs.brightnessctl ];
    text = ''
      case "''${1:-}" in
        up) brightnessctl -n2 set 5%+ ;;
        down) brightnessctl -n2 set 5%- ;;
        *) echo "usage: brightness-step up|down" >&2; exit 2 ;;
      esac
    '';
  };

  # Ends the Hyprland session, through hyprshutdown if it's installed (which
  # closes apps gracefully first). Used by SUPER+M and the start menu.
  logOut = pkgs.writeShellApplication {
    name = "session-logout";
    text = ''
      if command -v hyprshutdown >/dev/null 2>&1; then
        exec hyprshutdown
      fi
      exec hyprctl dispatch 'hl.dsp.exit()'
    '';
  };

  # Everything the hand-written Lua (home/hypr/) needs from Nix, as
  # require("nix"). home/hypr/types/nix.lua describes it for the language
  # server; keep the two in step.
  nixValues = {
    screenshot = lib.getExe screenshot;
    screenshot_window = lib.getExe screenshotWindow;
    screenshot_screen = lib.getExe screenshotScreen;
    brightness_step = lib.getExe brightnessStep;
    log_out = lib.getExe logOut;
  };

  # The modules in home/hypr/ that main.lua requires
  luaModules = [ "main" "settings" "binds" "rules" "fullscreen" ];

  # Hyprland reloads by itself when a switch replaces a file it has loaded,
  # but that can happen before the switch has created the rest: replacing
  # hyprland.lua while main.lua didn't exist yet left it on a config that
  # failed to load, with only its emergency binds. Home-manager runs onChange
  # after every link is in place, so reload once more then. It runs once per
  # changed file; the variable keeps it to one reload per activation.
  reloadHyprland = ''
    if [[ -z "''${hyprlandReloaded:-}" ]]; then
      hyprlandReloaded=1
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      if [[ -d "$XDG_RUNTIME_DIR/hypr" ]]; then
        for i in $(${hyprctl} instances -j | ${lib.getExe pkgs.jq} -r '.[].instance'); do
          ${hyprctl} -i "$i" reload config-only >/dev/null || true
        done
      fi
    fi
  '';
  # The same package as programs.hyprland.package in the NixOS config
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
in
{
  # The XCursor version is for clients that draw their own cursor, like slurp.
  # playerctl is for the media key binds. The bar runs brightness-step
  # and session-logout too, so they're on PATH.
  home.packages = [ pkgs.rose-pine-hyprcursor pkgs.rose-pine-cursor pkgs.playerctl brightnessStep logOut ];

  xdg.configFile = lib.listToAttrs (map (name: {
    name = "hypr/${name}.lua";
    value = {
      source = ./hypr/${name}.lua;
      onChange = reloadHyprland;
    };
  }) luaModules) // {
    "hypr/nix.lua" = {
      text = "return ${lib.generators.toLua { } nixValues}\n";
      onChange = reloadHyprland;
    };
    # Generated by home-manager's Hyprland module
    "hypr/hyprland.lua".onChange = reloadHyprland;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    # Installed by programs.hyprland in the NixOS config
    package = null;
    portalPackage = null;
    configType = "lua";

    # The rest of the config is hand-written Lua in home/hypr/, loaded last.
    # Only what other Nix code changes stays here: the test VM
    # (modules/vm.nix) overrides the monitor and settings.config.input.accel_profile,
    # so home/hypr/ mustn't set those. Home-manager adds its startup hook.
    settings.monitor = {
      output = "";
      mode = "preferred";
      position = "auto";
      scale = "auto";
    };

    extraConfig = ''require("main")'';
  };
}
