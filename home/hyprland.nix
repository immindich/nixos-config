{ lib, pkgs, ... }:
let
  inline = lib.generators.mkLuaInline;

  mainMod = "SUPER";
  terminal = "kitty";
  fileManager = "dolphin";

  # Drag to select a region; saves to ~/screenshots and copies to the clipboard.
  # Does nothing if a selection is already in progress.
  screenshot = pkgs.writeShellApplication {
    name = "screenshot-region";
    runtimeInputs = [ pkgs.grim pkgs.slurp pkgs.wl-clipboard pkgs.util-linux ];
    text = ''
      exec 9>"$XDG_RUNTIME_DIR/screenshot-region.lock"
      flock -n 9 || exit 0
      dir="$HOME/screenshots"
      mkdir -p "$dir"
      file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
      region=$(slurp) || exit 0
      grim -g "$region" "$file"
      # wl-copy stays running to serve the clipboard; don't let it hold the lock
      wl-copy --type image/png < "$file" 9>&-
    '';
  };

  # Capture the focused window via the compositor (works even if it's partly
  # covered); saves to ~/screenshots, copies to the clipboard, plays a sound.
  screenshotWindow = pkgs.writeShellApplication {
    name = "screenshot-window";
    runtimeInputs = [ pkgs.grim pkgs.jq pkgs.wl-clipboard pkgs.pipewire ];
    text = ''
      id=$(hyprctl activewindow -j | jq -r '.stableId // empty')
      [ -n "$id" ] || exit 0
      dir="$HOME/screenshots"
      mkdir -p "$dir"
      file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
      grim -T "$id" "$file"
      pw-play ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/screen-capture.oga &
      wl-copy --type image/png < "$file"
    '';
  };

  bind = key: dsp: { _args = [ key (inline dsp) ]; };
  bindWith = key: dsp: opts: { _args = [ key (inline dsp) opts ]; };
  exec = cmd: "hl.dsp.exec_cmd(${builtins.toJSON cmd})";
  mediaOpts = { locked = true; repeating = true; };
  # Triggers a Quickshell GlobalShortcut with appid "quickshell"
  shellShortcut = name: ''hl.dsp.global("quickshell:${name}")'';

  bezier = name: p1: p2: { _args = [ name { type = "bezier"; points = [ p1 p2 ]; } ]; };
  anim = leaf: speed: extra: { inherit leaf speed; enabled = true; } // extra;

  # SUPER + [0-9] switches workspace, SUPER + SHIFT + [0-9] moves the window without following it
  workspaceBinds = lib.concatMap (
    i:
    let
      key = toString (lib.mod i 10); # 10 maps to key 0
      ws = toString i;
    in
    [
      (bind "${mainMod} + ${key}" "hl.dsp.focus({ workspace = ${ws} })")
      (bind "${mainMod} + SHIFT + ${key}" "hl.dsp.window.move({ workspace = ${ws}, follow = false })")
    ]
  ) (lib.range 1 10);
in
{
  # The XCursor version is for clients that draw their own cursor, like slurp.
  # playerctl is for the media key binds below.
  home.packages = [ pkgs.rose-pine-hyprcursor pkgs.rose-pine-cursor pkgs.playerctl ];

  wayland.windowManager.hyprland = {
    enable = true;
    # Installed by programs.hyprland in the NixOS config
    package = null;
    portalPackage = null;
    configType = "lua";

    settings = {
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = "auto";
      };

      env = [
        { _args = [ "XCURSOR_THEME" "BreezeX-RosePine-Linux" ]; }
        { _args = [ "XCURSOR_SIZE" "24" ]; }
        { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
        { _args = [ "HYPRCURSOR_THEME" "rose-pine-hyprcursor" ]; }
      ];

      config = {
        general = {
          gaps_in = 3;
          gaps_out = 6;
          border_size = 1;
          # Tokyo Night, matching the bar's Theme.qml (accent, dimTextColor)
          col = {
            active_border = "rgba(7aa2f7ee)";
            inactive_border = "rgba(565f89aa)";
          };
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
          rounding = 5;
          rounding_power = 2;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = inline "0xee1a1a1a";
          };
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };

        animations.enabled = true;
        binds.movefocus_cycles_groupfirst = true;
        dwindle.preserve_split = true;
        master.new_status = "master";
        scrolling.fullscreen_on_one_column = true;
        xwayland.force_zero_scaling = true;

        misc = {
          disable_hyprland_logo = true;
          focus_on_activate = true;
        };

        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "ctrl:nocaps";
          kb_rules = "";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad = {
	          natural_scroll = true;
	          tap_to_click = false;
            clickfinger_behavior = true;
          };
        };
      };

      curve = [
        (bezier "easeOutQuint" [ 0.23 1 ] [ 0.32 1 ])
        (bezier "easeInOutCubic" [ 0.65 0.05 ] [ 0.36 1 ])
        (bezier "linear" [ 0 0 ] [ 1 1 ])
        (bezier "almostLinear" [ 0.5 0.5 ] [ 0.75 1 ])
        (bezier "quick" [ 0.15 0 ] [ 0.1 1 ])
        {
          _args = [
            "easy"
            {
              type = "spring";
              mass = 1;
              stiffness = 71.2633;
              dampening = 15.8273644;
            }
          ];
        }
      ];

      animation = [
        (anim "global" 10 { bezier = "default"; })
        (anim "border" 5.39 { bezier = "easeOutQuint"; })
        (anim "windows" 4.79 { spring = "easy"; })
        (anim "windowsIn" 4.1 { spring = "easy"; style = "popin 87%"; })
        (anim "windowsOut" 1.49 { bezier = "linear"; style = "popin 87%"; })
        (anim "fadeIn" 1.73 { bezier = "almostLinear"; })
        (anim "fadeOut" 1.46 { bezier = "almostLinear"; })
        (anim "fade" 3.03 { bezier = "quick"; })
        (anim "layers" 3.81 { bezier = "easeOutQuint"; })
        (anim "layersIn" 4 { bezier = "easeOutQuint"; style = "fade"; })
        (anim "layersOut" 1.5 { bezier = "linear"; style = "fade"; })
        (anim "fadeLayersIn" 1.79 { bezier = "almostLinear"; })
        (anim "fadeLayersOut" 1.39 { bezier = "almostLinear"; })
        (anim "workspaces" 1.94 { bezier = "almostLinear"; style = "fade"; })
        (anim "workspacesIn" 1.21 { bezier = "almostLinear"; style = "fade"; })
        (anim "workspacesOut" 1.94 { bezier = "almostLinear"; style = "fade"; })
        (anim "zoomFactor" 7 { bezier = "quick"; })
      ];

      gesture = {
        fingers = 4;
        direction = "horizontal";
        action = "workspace";
      };

      bind = [
        (bind "${mainMod} + Return" (exec terminal))
        (bind "${mainMod} + C" "hl.dsp.window.close()")
        (bind "${mainMod} + M" (exec "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
        (bind "${mainMod} + Escape" (exec "pidof hyprlock || hyprlock"))
        (bind "${mainMod} + E" (exec fileManager))
        (bind "${mainMod} + V" ''hl.dsp.window.float({ action = "toggle" })'')
        # Tapping SUPER on its own toggles the Quickshell start menu
        (bindWith "${mainMod} + Super_L" (exec "qs ipc call startmenu toggle") { release = true; })
        (bind "${mainMod} + SHIFT + V" (exec "qs ipc call clipboard toggle"))
        (bind "${mainMod} + P" "hl.dsp.window.pseudo()")
        (bind "${mainMod} + T" ''hl.dsp.layout("togglesplit")'') # dwindle only
        (bind "Print" (exec (lib.getExe screenshot)))
        (bind "SHIFT + Print" (exec (lib.getExe screenshotWindow)))
        (bind "${mainMod} + SHIFT + P" (exec (lib.getExe screenshot)))

        (bind "${mainMod} + H" ''hl.dsp.focus({ direction = "left" })'')
        (bind "${mainMod} + L" ''hl.dsp.focus({ direction = "right" })'')
        (bind "${mainMod} + K" ''hl.dsp.focus({ direction = "up" })'')
        (bind "${mainMod} + J" ''hl.dsp.focus({ direction = "down" })'')

        (bind "${mainMod} + SHIFT + H" ''hl.dsp.window.move({ direction = "left", group_aware = true })'')
        (bind "${mainMod} + SHIFT + L" ''hl.dsp.window.move({ direction = "right", group_aware = true })'')
        (bind "${mainMod} + SHIFT + K" ''hl.dsp.window.move({ direction = "up", group_aware = true })'')
        (bind "${mainMod} + SHIFT + J" ''hl.dsp.window.move({ direction = "down", group_aware = true })'')

        (bind "${mainMod} + W" ''hl.dsp.group.toggle()'')
        (bind "${mainMod} + TAB" "hl.dsp.group.next()")
        (bind "${mainMod} + SHIFT + TAB" "hl.dsp.group.prev()")
        # Window switcher (home/quickshell/WindowSwitcher.qml); the shell
        # enters the alttab submap below while it's open
        (bind "ALT + TAB" (shellShortcut "alttab-open"))
      ]
      ++ workspaceBinds
      ++ [
        # Scratchpad
        (bind "${mainMod} + S" ''hl.dsp.workspace.toggle_special("magic")'')
        (bind "${mainMod} + SHIFT + S" ''hl.dsp.window.move({ workspace = "special:magic silent" })'')
        # The test VM's window (modules/vm.nix) lives on special:vm
        (bind "${mainMod} + SHIFT + M" ''hl.dsp.workspace.toggle_special("vm")'')

        # Scroll through existing workspaces
        (bind "${mainMod} + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'')
        (bind "${mainMod} + mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'')

        # Move/resize with LMB/RMB drag
        (bindWith "${mainMod} + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
        (bindWith "${mainMod} + mouse:273" "hl.dsp.window.resize()" { mouse = true; })

        # Volume and brightness keys
        # Changing the volume also unmutes (wpctl doesn't on its own)
        (bindWith "XF86AudioRaiseVolume" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+") mediaOpts)
        (bindWith "XF86AudioLowerVolume" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") mediaOpts)
        (bindWith "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") mediaOpts)
        (bindWith "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") mediaOpts)
        (bindWith "XF86MonBrightnessUp" (exec "brightnessctl -e4 -n2 set 5%+") mediaOpts)
        (bindWith "XF86MonBrightnessDown" (exec "brightnessctl -e4 -n2 set 5%-") mediaOpts)

        # Media keys
        (bindWith "XF86AudioNext" (exec "playerctl next") { locked = true; })
        (bindWith "XF86AudioPause" (exec "playerctl play-pause") { locked = true; })
        (bindWith "XF86AudioPlay" (exec "playerctl play-pause") { locked = true; })
        (bindWith "XF86AudioPrev" (exec "playerctl previous") { locked = true; })
      ];

      # Active while the window switcher is open. Tab and SHIFT+Tab move the
      # selection, letting go of ALT picks the window, Escape or any other key
      # cancels. The shell leaves the submap when it closes.
      define_submap = {
        _args = [
          "alttab"
          (inline ''
            function()
              hl.bind("ALT + TAB", ${shellShortcut "alttab-next"}, { repeating = true })
              hl.bind("ALT + SHIFT + TAB", ${shellShortcut "alttab-prev"}, { repeating = true })
              hl.bind("Alt_L", ${shellShortcut "alttab-commit"}, { release = true, ignore_mods = true })
              hl.bind("Alt_R", ${shellShortcut "alttab-commit"}, { release = true, ignore_mods = true })
              -- SHIFT is held for SHIFT+TAB; pressing it mustn't cancel
              hl.bind("Shift_L", hl.dsp.no_op(), { ignore_mods = true })
              hl.bind("Shift_R", hl.dsp.no_op(), { ignore_mods = true })
              hl.bind("catchall", ${shellShortcut "alttab-cancel"}, { ignore_mods = true })
            end
          '')
        ];
      };

      window_rule = [
        {
          # Ignore maximize requests from all apps
          name = "suppress-maximize-events";
          match.class = ".*";
          suppress_event = "maximize";
        }
        {
          # Fix some dragging issues with XWayland
          name = "fix-xwayland-drags";
          match = {
            class = "^$";
            title = "^$";
            xwayland = true;
            float = true;
            fullscreen = false;
            pin = false;
          };
          no_focus = true;
        }
        {
          name = "move-hyprland-run";
          match.class = "hyprland-run";
          move = "20 monitor_h-120";
          float = true;
        }
        {
          name = "claude-desktop-magic";
          match.class = "com.anthropic.Claude";
          workspace = "special:magic silent";
        }
        {
          # The test VM (modules/vm.nix) opens out of the way; SUPER+SHIFT+M shows it
          name = "test-vm";
          match = {
            class = "qemu";
            title = "^QEMU \\(laptop-vm\\)$";
          };
          workspace = "special:vm silent";
        }
      ];
    };
  };
}
