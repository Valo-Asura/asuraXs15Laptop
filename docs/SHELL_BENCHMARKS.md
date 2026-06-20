# Hyprland Shell Profile Checks

Updated: 2026-06-19 11:34 IST

Host: `asura-xs15`

Active session: `Noctalia + Hyprland`

MangoWM has been removed from the active NixOS configuration. Shell
experiments are optional profiles inside the normal Hyprland login session.

## Current Baseline

Captured in the normal `Noctalia + Hyprland` login session without restarting
the Noctalia service. The Noctalia service cgroup can contain apps launched
from the desktop, so comparisons use direct process RSS.

| Date | Session | Shell processes | Sample | Shell CPU % | Compositor CPU % | System CPU % | Shell RSS MB | Compositor RSS MB | Wrapper RSS MB | Load avg | RAM used | Screenshot |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|
| 2026-06-19 | Hyprland + Noctalia v5 | 1 | 15s | 0.800 | 10.000 | 5.214 | 156.1 | 149.6 | 5.2 | 2.08 1.80 0.93 | 4104/15687 MB | [bench-hyprland-noctalia-baseline-20260619-083019.png](../screenshots/bench-hyprland-noctalia-baseline-20260619-083019.png) |

## Ported Profiles

| Profile | Runtime path after rebuild | Launcher command | Status |
|---|---|---|---|
| Noctalia v5 | systemd user service | `noctalia msg panel-toggle launcher` on bare Super release | Stable default |
| Waybar import | `/etc/xdg/waybar-asura` | `asura-waybar` | Optional left vertical pill bar, replaces the active shell profile |
| Tide Island | `/etc/xdg/quickshell/tide-island` | `qs ipc ... call tide toggleControlCenter` | Experimental, Nix-built Qt/QML backend |
| Dotfiles | `/etc/xdg/quickshell/dotfiles` | `qs ipc ... call qsIpc toggleAppLauncher` | Experimental |
| Ricelin pill | `/etc/xdg/quickshell/ricelin/pill` | `qs ipc ... call pill launcher <monitor>` | Experimental |
| Caelestia | `/etc/xdg/quickshell/caelestia` | `caelestia shell drawers toggle launcher` | Experimental |

`SUPER+A` remains profile-aware through `asura-shell-launcher`. Bare
`SUPER_L`/`SUPER_R` release opens the Noctalia app launcher directly.

## Idle And Working Memory

Captured on 2026-06-19 in the live Hyprland session while Noctalia was still
available as the stable fallback. Current switcher behavior is stricter:
selecting an optional profile stops the other managed shell processes first.

CPU is sampled from `/proc/<pid>/stat` after the shell has settled, where
`100%` is one full CPU core. Memory is direct process RSS in decimal MB
(`rss_kB / 1000`), not whole-system RAM or systemd cgroup memory.

| Rank | Profile | Processes | Settle ms | Idle RSS MB | Idle CPU % | Working RSS MB | Working CPU % | System RAM MB | Load avg | Working screenshot |
|---:|---|---:|---:|---:|---:|---:|---:|---|---|---|
| 1 | Waybar import | 1 | 4000 | 91.5 | 0.000 | 91.5 | 0.000 | 6614/15687 | 2.12 2.48 2.45 | [waybar-vertical-pill-proof-20260619.png](../screenshots/waybar-vertical-pill-proof-20260619.png) |
| 2 | Noctalia v5 | 1 | live | 144.1 | 2.000 | 168.6 | 2.000 | 6627/15687 | 2.15 2.50 2.46 | [bench-shell-noctalia-working-20260619-113414.png](../screenshots/bench-shell-noctalia-working-20260619-113414.png) |
| 3 | Dotfiles | 1 | 4012 | 316.7 | 28.333 | 334.0 | 16.000 | 6897/15687 | 2.76 2.60 2.49 | [bench-shell-dotfiles-working-20260619-113414.png](../screenshots/bench-shell-dotfiles-working-20260619-113414.png) |
| 4 | Tide Island | 1 | 4011 | 333.0 | 0.333 | 333.3 | 0.333 | 6700/15687 | 2.35 2.51 2.47 | [bench-shell-tide-island-working-20260619-113414.png](../screenshots/bench-shell-tide-island-working-20260619-113414.png) |
| 5 | Ricelin pill | 1 | 4012 | 435.7 | 7.333 | 436.6 | 22.000 | 6982/15687 | 3.19 2.71 2.53 | [bench-shell-ricelin-working-20260619-113414.png](../screenshots/bench-shell-ricelin-working-20260619-113414.png) |
| 6 | Caelestia | 1 | 4014 | 609.4 | 4.333 | 605.4 | 14.000 | 6865/15687 | 2.93 2.67 2.52 | [bench-shell-caelestia-working-20260619-113414.png](../screenshots/bench-shell-caelestia-working-20260619-113414.png) |

Result: Waybar is the lightest imported bar, but it is not a full shell.
Selecting Waybar now stops Noctalia and other optional shell processes like the
other switch profiles. Noctalia remains the recommended default full desktop
shell. Tide Island is
viable as an opt-in dynamic island profile because it settled at low CPU after
startup. Dotfiles, Ricelin, and Caelestia are heavier experiments.

## Proof Screenshots

Captured in the live Hyprland session. Temporary test processes were killed
after each capture.

| Profile | Proof |
|---|---|
| Noctalia launcher | [bench-shell-noctalia-working-20260619-113414.png](../screenshots/bench-shell-noctalia-working-20260619-113414.png) |
| Waybar vertical pill | [waybar-vertical-pill-proof-20260619.png](../screenshots/waybar-vertical-pill-proof-20260619.png) |
| Waybar vertical crop | [waybar-vertical-pill-crop-20260619.png](../screenshots/waybar-vertical-pill-crop-20260619.png) |
| Tide Island control center | [bench-shell-tide-island-working-20260619-113414.png](../screenshots/bench-shell-tide-island-working-20260619-113414.png) |
| Dotfiles launcher | [bench-shell-dotfiles-working-20260619-113414.png](../screenshots/bench-shell-dotfiles-working-20260619-113414.png) |
| Ricelin launcher | [bench-shell-ricelin-working-20260619-113414.png](../screenshots/bench-shell-ricelin-working-20260619-113414.png) |
| Caelestia launcher | [bench-shell-caelestia-working-20260619-113414.png](../screenshots/bench-shell-caelestia-working-20260619-113414.png) |

## Validation

```bash
bash -n asura-xs15/quickshell/scripts/asura-quickshell-switch \
  asura-xs15/quickshell/scripts/asura-shell-launcher \
  asura-xs15/waybar/scripts/sysbar.sh \
  asura-xs15/waybar/scripts/workspaces.sh

nixfmt --check \
  system/default.nix \
  asura-xs15/system/default.nix \
  asura-xs15/system/login.nix \
  asura-xs15/hyprland/bindings.nix \
  asura-xs15/quickshell/default.nix

nix build /etc/nixos#nixosConfigurations.asura-xs15.config.system.build.toplevel \
  --no-link --print-out-paths
```

Latest successful toplevel:

```text
/nix/store/8ajdydm15dg48fnlxa598zg6lnx5gmg7-nixos-system-asura-xs15-26.11.20260616.567a49d
```

## Commands

```bash
asura-quickshell-switch status
asura-quickshell-switch noctalia
asura-quickshell-switch waybar
asura-quickshell-switch tide-island
asura-quickshell-switch caelestia
asura-quickshell-switch ricelin
asura-quickshell-switch dotfiles
asura-quickshell-switch stop-quickshell
```

`Noctalia + Hyprland` remains the only greetd session entry. The optional
profiles are selected inside that session and are not login sessions.
