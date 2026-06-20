# Hyprland Quickshell Profiles

The old isolated MangoWM session has been removed from the active NixOS
configuration. The useful shell experiments are now optional profiles for the
normal `Noctalia + Hyprland` session.

## Paths

| Item | Path |
|---|---|
| Module | `/etc/nixos/asura-xs15/quickshell/default.nix` |
| Caelestia source | `/etc/nixos/asura-xs15/quickshell/profiles/caelestia` |
| Ricelin source | `/etc/nixos/asura-xs15/quickshell/profiles/ricelin` |
| Dotfiles source | `/etc/nixos/asura-xs15/quickshell/profiles/dotfiles` |
| Tide Island source | `/etc/nixos/asura-xs15/quickshell/profiles/tide-island` |
| Waybar source | `/etc/nixos/asura-xs15/waybar` |
| Runtime Caelestia path | `/etc/xdg/quickshell/caelestia` |
| Runtime Ricelin path | `/etc/xdg/quickshell/ricelin` |
| Runtime Dotfiles path | `/etc/xdg/quickshell/dotfiles` |
| Runtime Tide Island path | `/etc/xdg/quickshell/tide-island` |
| Runtime Waybar path | `/etc/xdg/waybar-asura` |

## Commands

```bash
asura-quickshell-switch status
asura-quickshell-switch noctalia
asura-quickshell-switch caelestia
asura-quickshell-switch ricelin
asura-quickshell-switch dotfiles
asura-quickshell-switch tide-island
asura-quickshell-switch waybar
asura-quickshell-switch stop-quickshell
```

`asura-shell-launcher` opens the launcher for the selected profile. Hyprland
binds `SUPER+A`, `SUPER+Period`, and `SUPER+SHIFT+E` through that helper.
Bare `SUPER_L`/`SUPER_R` release opens the Noctalia app launcher directly.

## Proof

Live Hyprland proof screenshots:

| Profile | Screenshot |
|---|---|
| Dotfiles launcher | `screenshots/hyprland-dotfiles-quickshell-proof-20260619.png` |
| Ricelin launcher | `screenshots/hyprland-ricelin-launcher-proof-20260619.png` |
| Caelestia launcher | `screenshots/hyprland-caelestia-launcher-proof-20260619.png` |
| Tide Island control center | `screenshots/bench-shell-tide-island-working-20260619-113414.png` |
| Waybar vertical pill | `screenshots/waybar-vertical-pill-proof-20260619.png` |
| Waybar vertical crop | `screenshots/waybar-vertical-pill-crop-20260619.png` |

## Safety

`noctalia.service` is configured with `KillMode=process` so stopping the shell
does not kill apps launched from the shell cgroup. The switcher refuses to stop
Noctalia if the live service still has the old `KillMode=control-group`; rebuild
first.

## Default

The default and recommended daily profile remains:

```bash
asura-quickshell-switch noctalia
```

The optional profiles are for testing and screenshots.

`waybar` is a left vertical pill bar-only profile. Switching to it stops
Noctalia and the other optional shell processes, the same as the Quickshell
test profiles. Return to the full desktop shell with:

```bash
asura-quickshell-switch noctalia
```
