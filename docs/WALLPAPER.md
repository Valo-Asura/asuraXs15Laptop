# Wallpaper Workflow

This system uses Noctalia as the active shell and keeps the wallpaper entry
point declarative through Home Manager. Image wallpaper selection is handled by
Noctalia. Video wallpaper is handled by `mpvpaper` through local helper scripts.

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

The wrapper opens Noctalia:

```bash
noctalia msg panel-toggle wallpaper
```

## Video Wallpaper

Apply a video wallpaper:

```bash
asura-video-wallpaper /path/to/wallpaper.mp4
```

If no path is passed, the helper picks the first `mp4`, `webm`, `mkv`, or
`mov` file under `/home/asura/Pictures/Wallpapers`.

Stop video wallpaper and return to the Noctalia image wallpaper:

```bash
asura-video-wallpaper-stop
```

Hyprland runs `asura-video-wallpaper --restore` on session start. It does
nothing unless a video path was previously stored in:

```text
~/.local/state/asura/video-wallpaper
```

## Paths

| Path | Purpose |
|---|---|
| `/home/asura/Pictures/Wallpapers` | Main wallpaper directory used by Noctalia settings |
| `/etc/nixos/asura-xs15/noctaliaShell/settings.toml` | Declarative Noctalia wallpaper and lockscreen settings |
| `/etc/nixos/asura-xs15/scripts/desktop-helpers.nix` | Declares Noctalia and `mpvpaper` wallpaper helpers |
| `/etc/nixos/asura-xs15/hyprland/bindings.nix` | Nix-owned Hyprland keybind source |
| `/etc/nixos/screenshots/lockscreen.png` | Noctalia lockscreen wallpaper |

## Validate

```bash
command -v asura-wallpaper-panel
command -v asura-video-wallpaper
command -v mpvpaper
asura-wallpaper-panel
asura-video-wallpaper /path/to/video.mp4
asura-video-wallpaper-stop
hyprctl binds | grep -F 'SUPER'
```

The expected `SUPER+W` path is Noctalia's wallpaper panel. Video wallpaper is
explicit so the shell does not start `mpvpaper` unless a video is selected.
