# vibewallREzero

Native C++ rewrite of the `skwd-wall` workflow for the Asura XS15 NixOS
desktop. It uses the local reference at `/home/asura/Downloads/skwd-wall-main`
for workflow and visual behavior, but does not use Qt, QML, Quickshell, GTK,
Tauri, Electron, or WebKit.

## Features

- Tiny daemon plus short-lived native picker.
- Native Wayland layer-shell overlay with OpenGL ES rendering.
- Three reference-inspired modes: slice carousel, grid, and hex.
- SQLite wallpaper database with tags, favourites, filters, colour groups, and
  last-used restore state.
- Image thumbnails through libvips and video thumbnails through ffmpeg.
- Wallhaven paginated search/cache/download/apply.
- Image backend: `noctalia msg wallpaper-set`.
- Video backend: `mpvpaper`.
- Theme hook: `matugen image`.

## Build

```bash
meson setup build
meson compile -C build
meson test -C build
```

## Commands

```bash
vibewall scan
vibewall toggle
vibewall picker --mode slice
vibewall picker --mode grid
vibewall picker --mode hex
vibewall apply /path/to/wallpaper.png
vibewall random
vibewall restore
vibewall wallhaven search "city night" --page 1
```

## Picker Keys

| Key | Action |
|---|---|
| `1` | Slice mode |
| `2` | Grid mode |
| `3` | Hex mode |
| `Left/Right/Up/Down` | Navigate |
| `Enter` | Apply selected |
| `F` | Toggle favourite |
| `/` | Edit search |
| `Backspace` | Delete search char |
| `Escape` | Close |

## NixOS

The module at `nix/module.nix` installs the package, enables the user daemon,
and exposes a `programs.vibewallREzero` option set.

## Performance

The daemon intentionally does not link Wayland/EGL/OpenGL/libvips/curl UI
paths. Heavy indexing, thumbnailing, Wallhaven, and rendering happen in
short-lived processes.

Run:

```bash
benchmark.sh
```
