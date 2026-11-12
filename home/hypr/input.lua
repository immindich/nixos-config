-- Input devices and gestures

hl.config({
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

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

-- By default, the touchpad is disabled when typing. This is fine
-- normally, but it can be a pain when playing certain games.
local function exempt(w)
  return w and w.class and (w.class:find("steam_app") or
    w.class == "dwarfort"
  )
end

hl.on("window.active", function(w)
  hl.config({
    input = {
      touchpad = {
        disable_while_typing = not exempt(w)
      }
    }
  })
end)
