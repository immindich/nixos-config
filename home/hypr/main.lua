-- Hand-written Hyprland config. home/hyprland.nix links these files into
-- ~/.config/hypr and has the generated hyprland.lua require this one last,
-- after the parts that stay in Nix (the monitor, which the test VM
-- overrides, and home-manager's startup hook). Store paths of the scripts
-- packaged in Nix come from require("nix"), which is generated; its shape is
-- described for the language server in types/nix.lua.

require("startup")

require("settings")
require("binds")
require("rules")
require("fullscreen")
require("input")
