# Wallpaper Workflow

This system uses Noctalia as the active shell and keeps the wallpaper entry
point declarative through Home Manager. `skwd-wall` is installed from its
upstream flake for the primary picker.

## Keybinds

| Keybind | Action |
|---|---|
| `SUPER+W` | Open wallpaper workflow |
| `SUPER+SHIFT+W` | Open wallpaper workflow |
| `SUPER+P` | Display manager |
| `SUPER+SHIFT+P` | Restore/reload display layout |

`SUPER+W` runs:

```bash
asura-wallpaper-panel
```

The wrapper tries `skwd-wall` first:

```bash
skwd wall toggle
```

If that command is unavailable or exits unsuccessfully, it falls back to
Noctalia:

```bash
noctalia msg panel-toggle wallpaper
```

## Paths

| Path | Purpose |
|---|---|
| `/home/asura/Pictures/Wallpapers` | Main wallpaper directory used by Noctalia settings |
| `github:liixini/skwd-wall` | Flake input for the primary wallpaper picker |
| `/etc/nixos/asura-xs15/noctaliaShell/settings.toml` | Declarative Noctalia wallpaper and lockscreen settings |
| `/etc/nixos/asura-xs15/scripts/desktop-helpers.nix` | Declares `asura-wallpaper-panel` |
| `/etc/nixos/asura-xs15/hyprland/bindings.nix` | Nix-owned Hyprland keybind source |
| `/etc/nixos/screenshots/lockscreen.png` | Noctalia lockscreen wallpaper |

## Validate

```bash
command -v asura-wallpaper-panel
command -v skwd
asura-wallpaper-panel
hyprctl binds | grep -F 'SUPER'
systemctl --user status skwd-daemon.service --no-pager
```

The expected path is `skwd wall toggle`. If it fails, Noctalia's wallpaper
panel should still open.
