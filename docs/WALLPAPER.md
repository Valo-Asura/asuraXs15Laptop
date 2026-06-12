# Wallpaper Workflow

This system uses Noctalia as the active shell, but wallpaper selection is handled
by `vibewallREzero`, a native C++23 Wayland picker/daemon under
`/etc/nixos/asuraPc/vibewallREzero`.

Images apply through Noctalia IPC:

```bash
noctalia msg wallpaper-set /path/to/image
```

Videos apply through `mpvpaper`:

```bash
mpvpaper --fork --auto-stop --layer background --mpv-options "no-audio loop hwdec=auto-safe profile=fast" "*" /path/to/video
```

## Keybinds

| Keybind | Action |
|---|---|
| `SUPER+W` | Toggle `vibewallREzero` picker |
| `SUPER+SHIFT+W` | Toggle `vibewallREzero` picker |
| `SUPER+P` | Display manager |
| `SUPER+SHIFT+P` | Restore/reload display layout |

`SUPER+W` runs:

```bash
vibewall toggle
```

Hyprland restores the last saved wallpaper on login with:

```bash
vibewall restore
```

## Picker Modes

The picker implements the three reference modes from `skwd-wall-main`:

| Mode | Proof |
|---|---|
| Slice carousel | `screenshots/vibewallrezero-slice.png` |
| Grid | `screenshots/vibewallrezero-grid.png` |
| Hex selector | `screenshots/vibewallrezero-hex.png` |

The picker toolbar exposes local and Wallhaven sources:

| Key | Action |
|---|---|
| `W` | Search/cache Wallhaven using the current search text or default query |
| `L` | Return to local wallpapers |
| `R` | Apply a random local wallpaper |
| `/` | Edit search text |
| `Enter` | Apply selected wallpaper |

## Commands

Index local wallpapers:

```bash
vibewall scan
```

Open the picker:

```bash
vibewall toggle
```

Apply an image or video:

```bash
vibewall apply /home/asura/Wallpaper/random_wallpaper.jpg
vibewall apply /home/asura/Wallpaper/chill.mp4
```

The last wallpaper is stored in the SQLite settings table and restored by
Hyprland on login. Video state is also mirrored for legacy helpers at:

```text
~/.local/state/asura/video-wallpaper
```

## Paths

| Path | Purpose |
|---|---|
| `/home/asura/Wallpaper` | Main image/video wallpaper directory |
| `/etc/nixos/asura-xs15/noctaliaShell/settings.toml` | Declarative Noctalia wallpaper and lockscreen settings |
| `/etc/nixos/asuraPc/vibewallREzero` | Native picker, daemon, CLI, tests, and Nix module |
| `/etc/nixos/asura-xs15/hyprland/bindings.nix` | Nix-owned Hyprland keybind source |
| `/etc/nixos/screenshots/lockscreen.png` | Noctalia lockscreen wallpaper |

## Validate

```bash
command -v vibewall
command -v mpvpaper
vibewall scan
vibewall toggle
vibewall apply /home/asura/Wallpaper/random_wallpaper.jpg
vibewall apply /home/asura/Wallpaper/chill.mp4
vibewall wallhaven search "anime landscape" --page 1
hyprctl binds | grep -F 'vibewall toggle'
```

Tested proof on 2026-06-12:

| Check | Result |
|---|---|
| Local scan | `images=34 videos=9 errors=0` |
| Picker modes | Slice, grid, and hex screenshots captured with `grim` |
| Wallhaven | CLI search returned results and cached `24` entries with `24` previews |
| Daemon toggle | `picker_pid` opens then returns to `-1` after close |
| Video apply | `mpvpaper` starts for video and is stopped after image restore |
