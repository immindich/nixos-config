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
- Don't run `nix flake update` or touch `flake.lock` unless I ask.
- The `homeConfigurations` output is for non-NixOS machines. It's fine to build it to check it evaluates, but never activate it on a NixOS machine.

## Git workflow

- Each new task gets its own branch off `main`, worked on in the `.worktrees/vm-dev` worktree (setup is in the `vm-test` skill). Never switch branches in the main checkout: the live bar reads its QML from there, and it holds my own uncommitted edits.
- Commit as you go, one commit per logical step, in the existing `<area>: <summary>` message style. End messages with the `Co-Authored-By` line only: never add a `Claude-Session` link, even if the attribution instructions include one. Don't commit anything broken: before each commit, build Nix changes, and check `qs log` in the VM for QML changes.
- Follow-ups to a task stay on its branch. Once the work is done and verified, ask before bringing it onto `main`. When I say yes: if the branch is behind `main`, rebase it onto `main` and re-check it first, then `git -C ~/nixos-config merge --ff-only <branch>`. If my uncommitted edits in the main checkout block the fast-forward, ask.
- Changes that only touch documentation (this file, skills, READMEs) can go straight onto `main` in the main checkout and be committed there, unless they clash with my uncommitted edits. Leave my uncommitted edits out of the commit.

## Test VM

`modules/vm.nix` defines a `virtualisation.vmVariant` of the laptop config that boots straight into Hyprland as isaiah, with the host's Nix store mounted read-only and a checkout shared in at `~/nixos-config`. Use it for desktop-shell work (Quickshell, Hyprland config) and for Nix changes that need to be run to be trusted, since activating on the host needs root. Don't use it for a simple Nix change that doesn't involve the shell and that you're reasonably confident will work the first time: the host has to be switched anyway, so the VM round-trip only adds time there.

The whole workflow, including the `vm-dev` worktree that code changes happen in, how to start and stop the guest, screenshots, and driving pointer and keyboard input, is the `vm-test` skill (`.claude/skills/vm-test/`), with helper scripts in its `scripts/` directory. Load it before any shell work.

## Conventions

- System services, hardware, drivers → `modules/` or the host file. User apps and dotfiles → `home/`.
- Never change `system.stateVersion` or `home.stateVersion`.
- Options must exist in the pinned 26.05 releases. Don't trust memory for option names; check with `nix eval` or `man configuration.nix` / `man home-configuration.nix`.
- Keep changes minimal. Don't reorganize files or add options I didn't ask for.

## Things that live outside Nix on purpose

- Python/ML: projects use `uv`; binary wheels work via `programs.nix-ld`. Don't package Python projects with nixpkgs. If a wheel fails to find a `.so`, add the library to `programs.nix-ld.libraries`.
- Claude Code: native installer in `~/.local/bin`, self-updating. Not managed by Nix.

## Hyprland

- Installed by NixOS `programs.hyprland`; home-manager's module is enabled in `home/hyprland.nix` with `package = null` and `portalPackage = null`.
- The config is hand-written Lua in `home/hypr/`: `main.lua` requires `settings.lua` (options, curves, animations), `binds.lua`, `rules.lua` and `fullscreen.lua`. A new module must also be added to `luaModules` in `home/hyprland.nix`, which links each file into `~/.config/hypr`. API reference: Hyprland's stubs, linked at `~/.config/hypr/stubs/hl.meta.lua`; `.luarc.json` points lua-language-server at them.
- `home/hyprland.nix` keeps the scripts packaged with `writeShellApplication` and hands their paths to the Lua as `require("nix")`, generated from `nixValues`. Keep `home/hypr/types/nix.lua`, the language server's description of that module, in step with `nixValues`.
- The generated `hyprland.lua` holds only the monitor, home-manager's startup hook and `require("main")`, which runs last. `modules/vm.nix` overrides the monitor and `settings.config.input.accel_profile` from Nix, so the Lua must never set those (it would win). Options in `settings` live under `settings.config.<section>`; a key directly under `settings.<section>` renders a separate `hl.<section>(...)` call that silently does nothing.
- The Lua files are in the Nix store, so a change needs a build and a switch (`vm-switch` in the VM). Hyprland reloads by itself when the switch replaces the links. To try something live first, `hyprctl eval '<lua>'` runs Lua in the compositor until the next reload (it isn't in `hyprctl --help`); it only answers `ok` or an error. `print()` writes `[Lua]` lines to `hyprctl rollinglog`, but only while the config sets `debug = { disable_logs = false }` (logging is off by default, and the logger only rereads that option on a config reload, so setting it with `hyprctl eval` doesn't help). Otherwise show values with `hl.notification.create({ text = ... })`.
- To check the rendering without switching:
  `nix eval --raw '.#nixosConfigurations.<host>.config.home-manager.users.isaiah.xdg.configFile."hypr/hyprland.lua".text'` (and `"hypr/nix.lua"`)
- To screenshot an app window (e.g. to check theming), capture the window itself rather than a screen region: I may switch workspaces while you test, and a region grab then shows whatever is on screen. Find the window's `stableId`, then capture it; this works even when the window is on a workspace that isn't visible:
  `grim -T "$(hyprctl clients -j | jq -r '.[] | select(.pid == <pid>) | .stableId')" <scratchpad>/window.png`
  (or select on `.class`).

## Quickshell

- The bar lives in `home/quickshell/` (plain QML, not generated by Nix). `home/common.nix` links it to `~/.config/quickshell` with `mkOutOfStoreSymlink`, so edits are live.
- Quickshell is running and reloads on save. Don't rebuild Nix or restart it for QML changes. New QML files don't need `git add` to work.
- The file watcher occasionally misses a change, especially when several files are written at once. The symptom is no new "Reloading configuration..." in `qs log`, or errors about properties that do exist. `touch` the changed file to force a reload.
- Docs: https://quickshell.org/docs/v0.3.0/ (installed version is 0.3.0). Check property names there rather than guessing.
- Styling (colors, font sizes, bar/bubble sizes) goes in the `Theme.qml` singleton; use `Theme.<name>` instead of hardcoding values. Colors come from the scheme named by `Theme.scheme`, one file per scheme in `home/quickshell/schemes/` (every one is listed in `Theme.schemes`; add a new one to that list). The look of menus (`menuStyle`: float, caret, drawer, tab, flush; outline, shadow, opacity, accent stripe) and of an open indicator (`activeStyle`) are Theme options, drawn by `menus/MenuFrame.qml` and `IndicatorPill.qml`. Popup-like surfaces (menus, tooltips, notifications, the OSD) use `Theme.menuColor` with `Theme.menuBorder`/`Theme.borderColor`, not `Theme.background`. SUPER+SHIFT+T opens `ThemeTweaker.qml`, which switches all of these live without saving anything.
- The whole shell scales with `Theme.fontSize` (designed at 14). Write every pixel size in new or changed QML as `Theme.px(n)`, with `n` the size at 14: widths, heights, margins, padding, spacing, radii, font and icon sizes, popup offsets, and offsets added to Theme sizes (`Theme.fontSize - Theme.px(2)`). Never use a bare number. For drawn strokes and shapes (`Shape`, `Canvas`, fractional line widths) multiply by `Theme.uiScale` instead, which doesn't round. Durations, opacities, counts and angles don't scale. To check a new part, temporarily set `fontSize` to about 20 and 10 in the VM and look for clipping or overlap.
- The bar can sit on either screen edge (`Theme.barPosition`, `"top"` or `"bottom"`). Anything that opens from the bar must follow `Theme.barOnBottom` and open toward the middle of the screen. Copy the anchoring in `DropdownMenu.qml` for popups and `KeyboardMenu.qml` for layer surfaces rather than assuming the bar is at the top. Check new parts in the VM with the bar at the bottom too.
- Icons are Font Awesome glyphs, which are Unicode private-use characters (U+E000–U+F8FF). Always write them as `\uXXXX` escapes, e.g. `""`, with a comment naming the icon. Never put the raw character in a file: raw glyphs read back to you as empty strings, so retyping code drops them, and `\u` escapes you emit sometimes land on disk as the raw character without you noticing. Move existing icon code with a scripted copy (python/sed), not by retyping. After any edit that touches icons, `grep -rlP '[\x{E000}-\x{F8FF}]' home/quickshell` must print nothing; if it does, convert with `re.sub(r"[-]", lambda m: "\\u%04x" % ord(m.group()), text)`. The pre-commit hook in `.githooks/` rejects commits that contain raw glyphs.
- `Text` defaults to `textFormat: Text.AutoText`, which renders HTML (including `<img>` tags that fetch URLs) whenever the string starts with a tag. Any `Text` showing a string from outside the shell (window titles, notification fields, SSIDs, Bluetooth and audio device names, media metadata, tray entries, clipboard previews) must set `textFormat: Text.PlainText`. Where markup is built on purpose (`AudioStreamSection.qml`), escape `&`, `<` and `>` in the interpolated strings.
- Hyprland runs in Lua mode: `Hyprland.dispatch()` takes a Lua dispatcher expression such as `hl.dsp.focus({ workspace = 1 })`, not the old `workspace 1` string syntax. See `home/hypr/binds.lua` and the stubs for the dispatcher names.
- `Hyprland.dispatch()` evaluates its argument as Lua inside the compositor, so a string that reaches it is code. Only build dispatches from numbers and values Hyprland itself produced (workspace ids, names from its config); never interpolate window titles, app names or other strings from outside the shell. If a string must be passed, wrap it with `JSON.stringify` so it becomes a quoted literal.
- Never name a property `on` + capital letter (`onAccent`): QML reads an assignment to it in a derived type as a signal handler and silently ignores it, so the base default wins.
- `console.log` output never reaches `qs log`; `console.warn` does, as `WARN qml:` lines. Remove them before landing.
- To inspect shell state without touching the running bar, run a throwaway instance: a file with a `ShellRoot`, no windows, and a `Timer` that logs with `console.warn` and calls `Qt.quit()`, started with `qs -p <file>`. This is safe on the host too.
- `DesktopEntries.heuristicLookup()` returns null for a few seconds after the shell starts, while entries are indexed, and the call isn't reactive. A binding that uses it should also read `DesktopEntries.applications.values` so it runs again once the index is ready.
- `HyprlandWorkspace.hasFullscreen` goes stale here: the Hyprland config moves a fullscreen window to a workspace of its own, and the flag often stays false on that workspace. Read `lastIpcObject.hasfullscreen` instead and call `Hyprland.refreshWorkspaces()` on the `fullscreen`, `movewindowv2`, `workspacev2` and `createworkspacev2` raw events (as the bar in `shell.qml` does). A throwaway `qs -p` instance saw `Hyprland.workspaces` empty even after 3 s (and `Bluetooth.defaultAdapter` null, though the bar sees it), so probe Hyprland state with temporary `console.warn` lines in the real config instead.
- Special workspaces: Hyprland sends `activespecial`/`activespecialv2` before the monitor's own state changes, so `Hyprland.refreshMonitors()` on that event still returns the old `specialWorkspace`; take the id from the `activespecialv2` data (`id,name,monitor`, empty id on close) instead. A fullscreen window on the regular workspace is still drawn over the top layer while a special workspace is shown over it, so a layer surface must be on the overlay layer to be seen there.
- A `HyprlandEvent` is gone once `onRawEvent` returns: read `event.name`/`event.data` into locals before using them in `Qt.callLater` or a timer.
- `PopupAnchor.item` has no change signal. A binding that reads `anchor.item` is evaluated once and goes stale, so for a popup whose anchor item changes at runtime, keep the item in a property of your own and set `anchor.rect` in `anchor.onAnchoring`. Calling `anchor.updateAnchor()` before the popup has ever been shown stops it from appearing; it's fine once visible.

After each change, verify it:

1. Check for QML errors and warnings: `qs log --no-color -t 40`
2. Screenshot just the panel and look at it: find its geometry with `hyprctl layers -j` (namespace `quickshell`), then `grim -g "x,y wxh" <scratchpad>/panel.png`. The screen is at 2x scale, so the PNG is twice the logical size. For pixel measurements (colors, padding, alignment), decode the PNG with `python3`.
3. To see a popup without clicking, temporarily set `visible: true` on it, screenshot, then remove the line.