{ lib, ... }:
let
  inline = lib.generators.mkLuaInline;

  mainMod = "SUPER";
  terminal = "foot";
  fileManager = "dolphin";
  menu = "hyprlauncher";

  bind = key: dsp: { _args = [ key (inline dsp) ]; };
  bindWith = key: dsp: opts: { _args = [ key (inline dsp) opts ]; };
  exec = cmd: "hl.dsp.exec_cmd(${builtins.toJSON cmd})";
  mediaOpts = { locked = true; repeating = true; };

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
        { _args = [ "XCURSOR_SIZE" "24" ]; }
        { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
      ];

      config = {
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          col = {
            active_border = {
              colors = [ "rgba(33ccffee)" "rgba(00ff99ee)" ];
              angle = 45;
            };
            inactive_border = "rgba(595959aa)";
          };
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
          rounding = 10;
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
        dwindle.preserve_split = true;
        master.new_status = "master";
        scrolling.fullscreen_on_one_column = true;

        misc = {
          force_default_wallpaper = -1;
          disable_hyprland_logo = false;
        };

        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "ctrl:nocaps";
          kb_rules = "";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad.natural_scroll = true;
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
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      };

      bind = [
        (bind "${mainMod} + Return" (exec terminal))
        (bind "${mainMod} + C" "hl.dsp.window.close()")
        (bind "${mainMod} + M" (exec "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
        (bind "${mainMod} + E" (exec fileManager))
        (bind "${mainMod} + V" ''hl.dsp.window.float({ action = "toggle" })'')
        (bind "${mainMod} + D" (exec menu))
        (bind "${mainMod} + P" "hl.dsp.window.pseudo()")
        (bind "${mainMod} + T" ''hl.dsp.layout("togglesplit")'') # dwindle only

        (bind "${mainMod} + H" ''hl.dsp.focus({ direction = "left" })'')
        (bind "${mainMod} + L" ''hl.dsp.focus({ direction = "right" })'')
        (bind "${mainMod} + K" ''hl.dsp.focus({ direction = "up" })'')
        (bind "${mainMod} + J" ''hl.dsp.focus({ direction = "down" })'')
      ]
      ++ workspaceBinds
      ++ [
        # Scratchpad
        (bind "${mainMod} + S" ''hl.dsp.workspace.toggle_special("magic")'')
        (bind "${mainMod} + SHIFT + S" ''hl.dsp.window.move({ workspace = "special:magic" })'')

        # Scroll through existing workspaces
        (bind "${mainMod} + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'')
        (bind "${mainMod} + mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'')

        # Move/resize with LMB/RMB drag
        (bindWith "${mainMod} + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
        (bindWith "${mainMod} + mouse:273" "hl.dsp.window.resize()" { mouse = true; })

        # Volume and brightness keys
        (bindWith "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+") mediaOpts)
        (bindWith "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") mediaOpts)
        (bindWith "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") mediaOpts)
        (bindWith "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") mediaOpts)
        (bindWith "XF86MonBrightnessUp" (exec "brightnessctl -e4 -n2 set 5%+") mediaOpts)
        (bindWith "XF86MonBrightnessDown" (exec "brightnessctl -e4 -n2 set 5%-") mediaOpts)

        # Media keys (requires playerctl)
        (bindWith "XF86AudioNext" (exec "playerctl next") { locked = true; })
        (bindWith "XF86AudioPause" (exec "playerctl play-pause") { locked = true; })
        (bindWith "XF86AudioPlay" (exec "playerctl play-pause") { locked = true; })
        (bindWith "XF86AudioPrev" (exec "playerctl previous") { locked = true; })
      ];

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
      ];
    };
  };
}
