-- Key and mouse binds, and the window switcher's submap

local nix = require("nix")

local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "dolphin"

local exec = hl.dsp.exec_cmd
local media_opts = { locked = true, repeating = true }

-- Triggers a Quickshell GlobalShortcut with appid "quickshell"
local function shell_shortcut(name)
  return hl.dsp.global("quickshell:" .. name)
end

-- Closes the window switcher (home/quickshell/WindowSwitcher.qml) with
-- shortcut `name` and leaves its submap; does nothing outside the submap
local function switcher_finish(name)
  return function()
    if hl.get_current_submap() == "alttab" then
      hl.dispatch(shell_shortcut(name))
      hl.dispatch(hl.dsp.submap("reset"))
    end
  end
end

hl.bind(mainMod .. " + Return", exec(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", exec(nix.log_out))
hl.bind(mainMod .. " + Escape", exec("pidof hyprlock || hyprlock"))
hl.bind(mainMod .. " + E", exec(fileManager))
-- Kitty floats at a set size, centred, rather than at its tiled size
hl.bind(mainMod .. " + V", function()
  hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  local w = hl.get_active_window()
  if w and w.floating and w.class == "kitty" and w.monitor then
    local m = w.monitor
    hl.dispatch(hl.dsp.window.resize({ x = math.floor(m.width / m.scale * 0.5), y = math.floor(m.height / m.scale * 0.6) }))
    hl.dispatch(hl.dsp.window.center())
  end
end)
-- Tapping SUPER on its own toggles the Quickshell start menu
hl.bind(mainMod .. " + Super_L", exec("qs ipc call startmenu toggle"), { release = true })
hl.bind(mainMod .. " + SHIFT + V", exec("qs ipc call clipboard toggle"))
-- Prompt box that starts a Claude Desktop chat (home/quickshell/ClaudePrompt.qml).
-- Off for now: the deep link only fills in Claude's message box, where
-- the app's own quick entry (CTRL+ALT+space) sends the message.
-- hl.bind(mainMod .. " + A", shell_shortcut("claude-prompt"))
-- Try colour schemes and look options live (ThemeTweaker.qml)
hl.bind(mainMod .. " + SHIFT + T", shell_shortcut("theme-tweaker"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind("Print", exec(nix.screenshot))
hl.bind("SHIFT + Print", exec(nix.screenshot_window))
hl.bind("ALT + Print", exec(nix.screenshot_screen))
hl.bind(mainMod .. " + SHIFT + P", exec(nix.screenshot))

-- Focus and move with the vim keys
for key, direction in pairs({ H = "left", L = "right", K = "up", J = "down" }) do
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = direction }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction, group_aware = true }))
end

hl.bind(mainMod .. " + W", hl.dsp.group.toggle())
hl.bind(mainMod .. " + TAB", hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.group.prev())
-- Window switcher (home/quickshell/WindowSwitcher.qml). Hyprland, not
-- the shell, enters and leaves the alttab submap, so letting go of ALT
-- straight away still closes it, and ALT can't get stuck in the submap
-- if Quickshell isn't running.
hl.bind("ALT + TAB", function()
  hl.dispatch(shell_shortcut("alttab-open"))
  hl.dispatch(hl.dsp.submap("alttab"))
end)
-- Letting go of ALT picks the window. A release bind only fires after
-- other keys (Tab) were pressed if it's transparent, which also lets
-- the app see ALT go up.
for _, alt in ipairs({ "Alt_L", "Alt_R" }) do
  hl.bind(alt, switcher_finish("alttab-commit"), { release = true, transparent = true, ignore_mods = true, submap_universal = true })
end

-- SUPER + [0-9] switches workspace, SUPER + SHIFT + [0-9] moves the window without following it
for ws = 1, 10 do
  local key = tostring(ws % 10) -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = ws }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws, follow = false }))
end

-- Scratchpad
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic silent" }))
-- The test VM's window (modules/vm.nix) lives on special:vm
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.workspace.toggle_special("vm"))

-- Claude Desktop's quick entry, which the app registers through the
-- GlobalShortcuts portal (see modules/claude-desktop.nix). The id is
-- what `hyprctl globalshortcuts` lists, and is tied to the app's profile
-- (~/.config/Claude), so it changes if that is reset. The app picks the
-- key, but the portal can't bind it, so it's bound here to match.
hl.bind("CTRL + ALT + space", hl.dsp.global("com.anthropic.Claude:0AAD7C444F61D669DCBB25DDA7C44871-Ctrl+Alt+Space"))

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with LMB/RMB drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume and brightness keys
-- Changing the volume also unmutes (wpctl doesn't on its own)
hl.bind("XF86AudioRaiseVolume", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), media_opts)
hl.bind("XF86AudioLowerVolume", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), media_opts)
hl.bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), media_opts)
hl.bind("XF86AudioMicMute", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), media_opts)
hl.bind("XF86MonBrightnessUp", exec(nix.brightness_step .. " up"), media_opts)
hl.bind("XF86MonBrightnessDown", exec(nix.brightness_step .. " down"), media_opts)

-- Media keys
hl.bind("XF86AudioNext", exec("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", exec("playerctl previous"), { locked = true })

-- Active while the window switcher is open. Tab and SHIFT+Tab move the
-- selection, Escape cancels. (A catchall can't cancel on other keys:
-- it fires on Tab too.)
hl.define_submap("alttab", function()
  hl.bind("ALT + TAB", shell_shortcut("alttab-next"), { repeating = true })
  hl.bind("ALT + SHIFT + TAB", shell_shortcut("alttab-prev"), { repeating = true })
  hl.bind("Escape", switcher_finish("alttab-cancel"), { ignore_mods = true })
end)
