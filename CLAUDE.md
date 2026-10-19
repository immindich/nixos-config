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