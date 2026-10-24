---
name: vm-test
description: Build, run and drive the NixOS test VM (modules/vm.nix) to verify changes before they land on the laptop. Covers the vm-dev worktree flow, starting and stopping the guest, restarting Quickshell in it, screenshots, and injecting pointer and keyboard input with the bundled vm-* scripts. Use it for any change under home/quickshell or to home/hyprland.nix, for any Nix change that has to be run to be trusted, and whenever a task involves the VM, the guest, vm-dev, or checking how the bar, a menu, a popup, a tooltip or hover behaves, even if the user doesn't say "VM".
---

# Testing in the VM

`modules/vm.nix` defines a `virtualisation.vmVariant` of the laptop config: the same system and home config, booting straight into Hyprland as isaiah. The guest mounts the host's Nix store read-only (nothing is copied) and shares a checkout read-only at `~/nixos-config`, so the Quickshell symlink resolves and QML edits are visible in the guest immediately. The host toplevel is unaffected by anything in that module.

The scripts referred to below live in `.claude/skills/vm-test/scripts/` of whichever checkout you're working in; run them by that path. They talk to the guest through the `vm` entry in `~/.ssh/config` (port 2222, key `~/.ssh/nixos-vm`). Guest sudo password is `isaiah`.

## When to use it

Use it for desktop-shell work (Quickshell, Hyprland config) and for Nix changes that need to be run to be trusted, since activating on the host needs root. Don't use it for a simple Nix change that doesn't involve the shell and that you're reasonably confident will work the first time: the host has to be switched anyway, so the VM round-trip only adds time there.

## Work in the `vm-dev` worktree

The live bar reads `~/nixos-config/home/quickshell` through a symlink, so any edit in the main checkout reloads the shell on the host, half-finished or not. Shell work happens in a worktree instead and reaches `main` only when it's verified.

- `~/nixos-config/.worktrees/vm-dev` is a worktree of this repo on the throwaway branch `vm-dev`. If it's missing: `git worktree add -b vm-dev .worktrees/vm-dev main`.
- Start by checking whether `vm-dev` is ahead of `main` (`git -C ~/nixos-config/.worktrees/vm-dev log main..vm-dev`) or has uncommitted edits (`git status`). If so, something from an earlier session never landed. Stop and ask what to do with it (land it, keep it, or drop it) before starting on the new task; don't rebase or reset over it.
- Then sync it: `git -C ~/nixos-config/.worktrees/vm-dev rebase main`. Commits already cherry-picked onto `main` drop out automatically.
- Edit in the worktree only, and run the VM from it, so the guest sees the worktree at `/home/isaiah/nixos-config`.
- Landing a change: commit on `vm-dev` in the worktree, then `git -C ~/nixos-config cherry-pick <sha>`. That edits the main checkout, so the live bar reloads at that moment; if it renders the old layout, `touch` the changed file. Nix changes still need a switch on the host, which the user does.
- `main` can only be checked out in one place, so don't switch the worktree to it; `vm-dev` is the branch for everything done there.

## Running the guest

```sh
cd ~/nixos-config/.worktrees/vm-dev
.claude/skills/vm-test/scripts/vm-up            # boots and waits until the bar is on screen (30-40 s)
.claude/skills/vm-test/scripts/vm-up --rebuild  # after a Nix change: nixos-rebuild build-vm first
.claude/skills/vm-test/scripts/vm-down          # power off and wait for QEMU to exit
```

- `vm-up` shares the checkout it's run from and refuses to start while a guest is running: the disk image and port 2222 are shared no matter which tree launched it. Power the guest off before launching from a different build.
- Nix changes (system, Hyprland config, user services): `git add` new files (the flake can't see untracked ones), `vm-down`, `vm-up --rebuild`. The qcow2 keeps the guest's home and store overlay, so windows are gone but settings persist.
- QML changes: `vm-qs restart`. inotify doesn't cross 9p, so the guest's Quickshell won't reload on its own. The script clears systemd's start limit first (a config error that crashes the shell a few times trips it), waits for "Configuration Loaded" or the load error, and prints it.
- The guest can't exercise the Intel driver, backlight, battery, Wi-Fi, Bluetooth or suspend. fprintd, tailscale, fwupd and Bluetooth are turned off in it, and the tailscale tray applet isn't started.
- The QEMU window opens on the host's special workspace `special:vm` (SUPER+SHIFT+M); the guest display is 1920x1200 at scale 2, like the laptop, so pixel measurements carry over.

## Looking at the result

```sh
S=.claude/skills/vm-test/scripts
$S/vm-exec hyprctl clients -j                   # any command, inside the Hyprland session environment
$S/vm-exec 'hyprctl dispatch "hl.dsp.exec_cmd(\"kitty --title test\")"'   # open a test window
$S/vm-qs log 40                                 # Quickshell log, minus the guest's hardware noise
$S/vm-shot <scratchpad>/panel.png               # the bar's own area
$S/vm-shot <scratchpad>/menu.png 0,0 500x300    # a region, logical pixels, like grim -g
$S/vm-shot <scratchpad>/full.png --full
```

- `hyprctl`, `qs`, `grim` and `wtype` need the session environment; `vm-exec` provides it. `ydotool` doesn't need it.
- Screenshots are twice the logical size. For colors, padding and alignment, decode the PNG with `python3` rather than eyeballing.
- A popup can be opened for real with the input below, or, as on the host, by temporarily setting `visible: true` on it, restarting, screenshotting, then removing the line.
- `console.log` from QML never reaches `qs log`; `console.warn` does, as `WARN qml:` lines. Remove them before landing.

## Driving input

```sh
$S/vm-pointer move 60 19       # jump to logical (60, 19); exact, the guest's pointer has a flat profile
$S/vm-pointer hover 60 19      # jump and wait for a tooltip or popup to open
$S/vm-pointer nudge 35 0       # relative move; HoverHandlers follow it
$S/vm-pointer click            # left click at the current position (or: click right)
$S/vm-pointer where            # hyprctl cursorpos
$S/vm-type htop                # type into the focused window
$S/vm-type -k Return           # press a key (wtype -k names)
```

- Allow for the UI's own delays before screenshotting: tooltips and the workspace list open after 500 ms, which `hover` already covers.
- Menus that take the keyboard (the launcher: `vm-exec qs ipc call startmenu toggle`) open as a Wayland popup grab, which the compositor only allows after the bar has received input. On a fresh boot that fails with "Failed to create grabbing popup" and nothing opens, so click the bar once first: `vm-pointer move 500 19; vm-pointer click`.
- Don't test hover through the QEMU window's own pointer or QMP `input-send-event`: both drive QEMU's usb-tablet, and the guest only delivers that device's enter, leave and clicks to Quickshell, not motion within a surface, so a HoverHandler never sees the pointer slide from one item to the next. `hl.dsp.cursor.move` warps the cursor without producing hover events at all. ydotool is a real uinput mouse and has none of these problems.
- The guest has no battery, so the battery indicator and its tooltip can't be exercised there.

## Keep this skill current

If you learn something new about driving the VM or testing in it (a technique that works or doesn't, a timing, a quirk of the guest, a script that would have saved repetition), add it here or to the scripts as part of the same task, in its own commit separate from the feature's. Lessons that only live in a session get lost; this file doesn't.
