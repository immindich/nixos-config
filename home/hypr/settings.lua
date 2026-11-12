-- Options, curves, animations and gestures

hl.env("XCURSOR_THEME", "BreezeX-RosePine-Linux")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")

-- Gap between windows and the screen edges; the bar's Theme.barMargin matches it
local gaps_out = 6

hl.config({
  general = {
    gaps_in = 3,
    gaps_out = gaps_out,
    border_size = 1,
    -- Tokyo Night's blue and grey. Set here, not taken from the bar's
    -- colour scheme (Theme.qml), so they don't follow it
    col = {
      active_border = "rgba(7aa2f7ee)",
      inactive_border = "rgba(565f89aa)",
    },
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 5,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = 0xee1a1a1a,
    },
    blur = {
      enabled = true,
      -- Strong enough to frost the bar's menus when Theme.menuOpacity
      -- is below 1 (see the layer rules)
      size = 8,
      passes = 3,
      vibrancy = 0.1696,
    },
  },

  animations = { enabled = true },
  binds = {
    -- Switching workspace (keys, bar, scroll) also closes an open
    -- special workspace instead of leaving it over the new one
    hide_special_on_workspace_change = true,
    movefocus_cycles_groupfirst = true,
  },
  dwindle = { preserve_split = true },
  master = { new_status = "master" },
  scrolling = { fullscreen_on_one_column = true },
  xwayland = { force_zero_scaling = true },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    focus_on_activate = true,
  },

  -- The test VM sets input.accel_profile from Nix (modules/vm.nix), so it
  -- mustn't be set here: this file runs after the Nix settings.
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "ctrl:nocaps",
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
      tap_to_click = false,
      clickfinger_behavior = true,
    },
  },
})

-- Curves come before the animations that use them
local function bezier(name, p1, p2)
  hl.curve(name, { type = "bezier", points = { p1, p2 } })
end
bezier("easeOutQuint", { 0.23, 1 }, { 0.32, 1 })
bezier("easeInOutCubic", { 0.65, 0.05 }, { 0.36, 1 })
bezier("linear", { 0, 0 }, { 1, 1 })
bezier("almostLinear", { 0.5, 0.5 }, { 0.75, 1 })
bezier("quick", { 0.15, 0 }, { 0.1, 1 })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

-- { leaf, speed, extra fields }
for _, a in ipairs({
  { "global", 10, { bezier = "default" } },
  { "border", 5.39, { bezier = "easeOutQuint" } },
  { "windows", 4.79, { spring = "easy" } },
  { "windowsIn", 4.1, { spring = "easy", style = "popin 87%" } },
  { "windowsOut", 1.49, { bezier = "linear", style = "popin 87%" } },
  { "fadeIn", 1.73, { bezier = "almostLinear" } },
  { "fadeOut", 1.46, { bezier = "almostLinear" } },
  { "fade", 3.03, { bezier = "quick" } },
  { "layers", 3.81, { bezier = "easeOutQuint" } },
  { "layersIn", 4, { bezier = "easeOutQuint", style = "fade" } },
  { "layersOut", 1.5, { bezier = "linear", style = "fade" } },
  { "fadeLayersIn", 1.79, { bezier = "almostLinear" } },
  { "fadeLayersOut", 1.39, { bezier = "almostLinear" } },
  { "workspaces", 1.94, { bezier = "almostLinear", style = "fade" } },
  { "workspacesIn", 1.21, { bezier = "almostLinear", style = "fade" } },
  { "workspacesOut", 1.94, { bezier = "almostLinear", style = "fade" } },
  { "zoomFactor", 7, { bezier = "quick" } },
}) do
  local spec = a[3]
  spec.leaf, spec.speed, spec.enabled = a[1], a[2], true
  hl.animation(spec)
end

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
