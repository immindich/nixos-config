-- A window that goes fullscreen moves to a workspace of its own, like
-- macOS, so switching to another window never has to take it out of
-- fullscreen (misc:on_focus_under_fullscreen). Workspaces from 101 up
-- are kept for these; the bar (home/quickshell/WorkspaceSwitcher.qml)
-- shows them after the others. Leaving fullscreen takes the window back,
-- if it's still alone there; closing it (quitting a game) takes you back
-- there instead, if you're still looking at its empty workspace. Handled
-- on a timer because the event fires inside Hyprland's fullscreen code,
-- and again (with the window still fullscreen) during the move itself.

-- Window selector ("address:...") -> the workspace id it left for fullscreen
local home = {}

hl.on("window.close", function(w)
  local window = "address:" .. w.address
  local id = home[window]
  if not id then return end
  home[window] = nil
  local left = w.workspace and w.workspace.id
  hl.timer(function()
    local active = hl.get_active_workspace()
    if active and active.id == left and active.windows == 0 then
      hl.dispatch(hl.dsp.focus({ workspace = id }))
    end
  end, { timeout = 1, type = "oneshot" })
end)

hl.on("window.fullscreen", function(w)
  local window = "address:" .. w.address
  hl.timer(function()
    local win = hl.get_window(window)
    if not win then
      home[window] = nil
      return
    end
    local ws = win.workspace
    if win.fullscreen == 2 then
      if not ws.special and ws.id <= 100 then
        home[window] = ws.id
        local id = 101
        while true do
          local target = hl.get_workspace(id)
          if not target or target.windows == 0 then break end
          id = id + 1
        end
        hl.dispatch(hl.dsp.window.move({ workspace = id, window = window }))
      end
    elseif win.fullscreen == 0 and home[window] then
      local id = home[window]
      home[window] = nil
      if ws.windows == 1 then
        hl.dispatch(hl.dsp.window.move({ workspace = id, window = window }))
      end
    end
  end, { timeout = 1, type = "oneshot" })
end)
