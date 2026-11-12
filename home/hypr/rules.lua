-- Window, layer and workspace rules

hl.window_rule({
  -- Ignore maximize requests from all apps
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})
hl.window_rule({
  -- Fix some dragging issues with XWayland
  name = "fix-xwayland-drags",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})
hl.window_rule({
  name = "move-hyprland-run",
  match = { class = "hyprland-run" },
  move = "20 monitor_h-120",
  float = true,
})
hl.window_rule({
  name = "steam-friends-float",
  match = { class = "^steam$", title = "^Friends List$" },
  float = true,
})
hl.window_rule({
  -- Only the main window: the quick entry popup is floating and has to
  -- open where it can be seen
  name = "claude-desktop-magic",
  match = { class = "com.anthropic.Claude", float = false },
  workspace = "special:magic silent",
})
hl.window_rule({
  -- The screenshot editor (Edit on a screenshot notification) floats
  name = "satty-float",
  match = { class = "^com\\.gabm\\.satty$" },
  float = true,
  size = "monitor_w*0.7 monitor_h*0.7",
  center = true,
})
hl.window_rule({
  -- The test VM (modules/vm.nix) opens out of the way; SUPER+SHIFT+M shows it
  name = "test-vm",
  match = { class = "qemu", title = "^QEMU \\(laptop-vm\\)$" },
  workspace = "special:vm silent",
})
hl.window_rule({
  -- A lone tiled window fills the screen (see the w[tv1] workspace rule)
  name = "single-window-no-border",
  match = { float = false, workspace = "w[tv1]" },
  border_size = 0,
  rounding = 0,
})

-- Blur what shows through the bar's menus when Theme.menuOpacity is
-- below 1: the layer surfaces themselves (the bar and the keyboard
-- menus) and the popups hanging off them. No effect while they're opaque.
for _, namespace in ipairs({ "quickshell", "quickshell-menu" }) do
  hl.layer_rule({
    match = { namespace = namespace },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.2,
  })
end

-- Keep 1-5 around when empty, so the workspace swipe can reach them
for ws = 1, 5 do
  hl.workspace_rule({ workspace = tostring(ws), persistent = true })
end
-- A single tiled window fills the screen up to the bar, without gaps
hl.workspace_rule({ workspace = "w[tv1]", gaps_in = 0, gaps_out = 0 })
