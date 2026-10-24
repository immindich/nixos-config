# nixos-config

Flake defining my NixOS machines and home-manager config. NixOS 26.05, home-manager release-26.05 (nixpkgs follows).

## Layout

- `flake.nix` — inputs, `nixosConfigurations.<host>`, and a standalone `homeConfigurations."isaiah@<host>"`
- `hosts/<host>/configuration.nix`, `hardware-configuration.nix` — per-machine config
- `modules/` — shared NixOS modules (system-level: services, hardware, desktop)
- `home/` — home-manager modules; `home/common.nix` is the entry point
- `secrets/` — sops-nix (not set up yet)

Home-manager runs as a NixOS module, so `nixos-rebuild` builds the system and home together.

## Checking changes

```sh
nixos-rebuild build --flake .#<host>     # builds ./result, changes nothing
nvd diff /run/current-system result      # what changed
nix eval .#nixosConfigurations.<host>.config.<option.path>   # check a single option's value
```

- Always build after editing. Don't run `nixos-rebuild switch`/`boot`, `sudo`, or `home-manager switch`. I activate changes myself.
- New files must be `git add`ed before building; the flake can't see untracked files and the error is confusing.
- Don't commit unless I ask.
- Don't run `nix flake update` or touch `flake.lock` unless I ask.
- The `homeConfigurations` output is for non-NixOS machines. It's fine to build it to check it evaluates, but never activate it on a NixOS machine.

## Test VM

`modules/vm.nix` defines a `virtualisation.vmVariant` of the laptop config: the same system and home config, booting straight into Hyprland as isaiah. The guest mounts the host's Nix store read-only (nothing is copied) and shares the checkout read-only at `~/nixos-config`, so the Quickshell symlink resolves and QML edits are visible in the guest immediately. The host toplevel is unaffected by anything in that module.

Use it for desktop-shell work (Quickshell, Hyprland config) and for Nix changes that need to be run to be trusted, since activating on the host needs root. Don't use it for a simple Nix change that doesn't involve the shell and that you're reasonably confident will work the first time: the host has to be switched anyway, so the VM round-trip only adds time there.

```sh
nixos-rebuild build-vm --flake .#laptop              # no root; writes ./result/bin/run-laptop-vm-vm
NIXOS_CONFIG_SRC=$PWD ./result/bin/run-laptop-vm-vm  # QEMU window, opens on special:vm (SUPER+SHIFT+M); disk image in ~/.cache/nixos-vm
ssh vm true                                          # ~/.ssh/config has a `vm` entry (port 2222, key ~/.ssh/nixos-vm)
```

- Run the VM in the background and poll `ssh vm true` until it succeeds (about 10 s). Guest sudo password is `isaiah`. Shut down with `ssh vm 'echo isaiah | sudo -S systemctl poweroff'`.
- Nix changes (system, Hyprland config, user services): rebuild the VM, power it off, relaunch. The qcow2 keeps the guest's home and store overlay.
- QML changes: inotify doesn't cross 9p, so the guest's Quickshell won't reload itself. Run `ssh vm systemctl --user restart quickshell`.
- `hyprctl`, `qs log` and `grim` over ssh need the session environment. Prefix commands with
  `export $(systemctl --user show-environment | grep -E '^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE)=' | xargs);`
  then the Quickshell verification steps below apply unchanged inside the guest; `scp vm:/tmp/panel.png` to look at the result. The guest display is 1920x1200 at scale 2, like the laptop, so pixel measurements carry over.
- The guest can't exercise the Intel driver, backlight, battery, Wi-Fi, Bluetooth or suspend. fprintd, tailscale, fwupd and Bluetooth are turned off in it, and the tailscale tray applet isn't started.

### Working in the `vm-dev` worktree

The live bar reads `~/nixos-config/home/quickshell` through a symlink, so any edit in the main checkout reloads the shell on the host. Shell work happens in a worktree instead, and reaches `main` only when it's verified.

- `~/nixos-config.vm` is a worktree of this repo on the throwaway branch `vm-dev`. If it's missing: `git worktree add -b vm-dev ../nixos-config.vm main`.
- Start a session by checking whether `vm-dev` is ahead of `main` (`git -C ~/nixos-config.vm log main..vm-dev`) or has uncommitted edits (`git status`). If so, something from an earlier session never landed. Stop and ask what to do with it (land it, keep it, or drop it) before starting on the new task; don't rebase or reset over it.
- Then sync it: `git -C ~/nixos-config.vm rebase main`. Commits already cherry-picked onto `main` drop out automatically.
- Build and run the VM from the worktree, and share the worktree into it:

  ```sh
  cd ~/nixos-config.vm
  nixos-rebuild build-vm --flake .#laptop             # cheap when nothing in Nix changed
  NIXOS_CONFIG_SRC=$PWD ./result/bin/run-laptop-vm-vm  # in the background
  ```

  The guest sees the worktree at `/home/isaiah/nixos-config` whatever its host path, so the Quickshell symlink resolves to it.
- Edit in the worktree only. QML: `ssh vm systemctl --user restart quickshell`, then check `qs log` and a screenshot inside the guest. Nix: `git add` new files, rebuild the VM, power it off, relaunch.
- Landing a change: commit on `vm-dev` in the worktree, then `git -C ~/nixos-config cherry-pick <sha>`. That edits the main checkout, so the live bar reloads at that moment; if it renders the old layout, `touch` the changed file. Nix changes still need a switch on the host.
- Only one VM runs at a time: the disk image and host port 2222 are shared no matter which tree launched it. Power the guest off before launching from a different build.
- `main` can only be checked out in one place, so don't switch the worktree to it; `vm-dev` is the branch for everything done there.

## Conventions

- System services, hardware, drivers → `modules/` or the host file. User apps and dotfiles → `home/`.
- Never change `system.stateVersion` or `home.stateVersion`.
- Options must exist in the pinned 26.05 releases. Don't trust memory for option names; check with `nix eval` or `man configuration.nix` / `man home-configuration.nix`.
- Keep changes minimal. Don't reorganize files or add options I didn't ask for.

## Things that live outside Nix on purpose

- Python/ML: projects use `uv`; binary wheels work via `programs.nix-ld`. Don't package Python projects with nixpkgs. If a wheel fails to find a `.so`, add the library to `programs.nix-ld.libraries`.
- Claude Code: native installer in `~/.local/bin`, self-updating. Not managed by Nix.

## Hyprland

- Installed by NixOS `programs.hyprland`; configured by home-manager in `home/hyprland.nix` with `package = null` and `portalPackage = null`.
- Config is Lua (`configType = "lua"`). Each `settings.<name>` becomes `hl.<name>(...)`; a list makes one call per element; `{ _args = [ ... ]; }` makes a multi-argument call; `lib.generators.mkLuaInline` emits raw Lua (used for `hl.dsp.*` dispatchers).
- Sections are written alphabetically, except `curve` goes first.
- Output lands at `~/.config/hypr/hyprland.lua`. To check the rendering without switching:
  `nix eval --raw '.#nixosConfigurations.<host>.config.home-manager.users.isaiah.xdg.configFile."hypr/hyprland.lua".text'`
- To screenshot an app window (e.g. to check theming), capture the window itself rather than a screen region: I may switch workspaces while you test, and a region grab then shows whatever is on screen. Find the window's `stableId`, then capture it; this works even when the window is on a workspace that isn't visible:
  `grim -T "$(hyprctl clients -j | jq -r '.[] | select(.pid == <pid>) | .stableId')" <scratchpad>/window.png`
  (or select on `.class`).

## Quickshell

- The bar lives in `home/quickshell/` (plain QML, not generated by Nix). `home/common.nix` links it to `~/.config/quickshell` with `mkOutOfStoreSymlink`, so edits are live.
- Quickshell is running and reloads on save. Don't rebuild Nix or restart it for QML changes. New QML files don't need `git add` to work.
- The file watcher occasionally misses a change, especially when several files are written at once. The symptom is no new "Reloading configuration..." in `qs log`, or errors about properties that do exist. `touch` the changed file to force a reload.
- Docs: https://quickshell.org/docs/v0.3.0/ (installed version is 0.3.0). Check property names there rather than guessing.
- Styling (colors, font sizes, bar/bubble sizes) goes in the `Theme.qml` singleton; use `Theme.<name>` instead of hardcoding values.
- Icons are Font Awesome glyphs, which are Unicode private-use characters (U+E000–U+F8FF). Always write them as `\uXXXX` escapes, e.g. `""`, with a comment naming the icon. Never put the raw character in a file: raw glyphs read back to you as empty strings, so retyping code drops them, and `\u` escapes you emit sometimes land on disk as the raw character without you noticing. Move existing icon code with a scripted copy (python/sed), not by retyping. After any edit that touches icons, `grep -rlP '[\x{E000}-\x{F8FF}]' home/quickshell` must print nothing; if it does, convert with `re.sub(r"[-]", lambda m: "\\u%04x" % ord(m.group()), text)`. The pre-commit hook in `.githooks/` rejects commits that contain raw glyphs.
- `Text` defaults to `textFormat: Text.AutoText`, which renders HTML (including `<img>` tags that fetch URLs) whenever the string starts with a tag. Any `Text` showing a string from outside the shell (window titles, notification fields, SSIDs, Bluetooth and audio device names, media metadata, tray entries, clipboard previews) must set `textFormat: Text.PlainText`. Where markup is built on purpose (`AudioStreamSection.qml`), escape `&`, `<` and `>` in the interpolated strings.
- Hyprland runs in Lua mode: `Hyprland.dispatch()` takes a Lua dispatcher expression such as `hl.dsp.focus({ workspace = 1 })`, not the old `workspace 1` string syntax. See `~/.config/hypr/hyprland.lua` for the dispatcher names.
- `Hyprland.dispatch()` evaluates its argument as Lua inside the compositor, so a string that reaches it is code. Only build dispatches from numbers and values Hyprland itself produced (workspace ids, names from its config); never interpolate window titles, app names or other strings from outside the shell. If a string must be passed, wrap it with `JSON.stringify` so it becomes a quoted literal.

After each change, verify it:

1. Check for QML errors and warnings: `qs log --no-color -t 40`
2. Screenshot just the panel and look at it: find its geometry with `hyprctl layers -j` (namespace `quickshell`), then `grim -g "x,y wxh" <scratchpad>/panel.png`. The screen is at 2x scale, so the PNG is twice the logical size. For pixel measurements (colors, padding, alignment), decode the PNG with `python3`.
3. To see a popup without clicking, temporarily set `visible: true` on it, screenshot, then remove the line.