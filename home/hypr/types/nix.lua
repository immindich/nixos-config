---@meta nix

-- For the language server only: describes the module that home/hyprland.nix
-- generates at ~/.config/hypr/nix.lua (its `nixValues`). Keep the two in step.

---@class Nix
---@field screenshot string Drag-select region screenshot (screenshot-region)
---@field screenshot_window string Screenshot of the focused window
---@field screenshot_screen string Screenshot of the focused monitor
---@field brightness_step string Steps the backlight; takes "up" or "down"
---@field log_out string Ends the session (session-logout)
local nix = {}

return nix
