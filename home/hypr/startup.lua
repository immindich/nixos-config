-- Commands that get executed when Hyprland starts, not on reload

hl.on("hyprland.start", function()
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
end)
