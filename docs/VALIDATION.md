# Validation

Run these after editing the flake:

```bash
nix flake check
nix build /etc/nixos#nixosConfigurations.asura-xs15.config.system.build.toplevel --no-link
sudo nixos-rebuild dry-build --flake /etc/nixos#asura-xs15
```

Run these after switching:

```bash
hostnamectl --static
systemctl --failed
nbfc-colorful-verify
nbfc status
systemctl status nbfc --no-pager
timeout 8s nbfc-gtk --fans || test "$?" = 124
gsettings get org.gnome.desktop.interface color-scheme
gsettings get org.gnome.desktop.interface gtk-theme
xdg-mime query default inode/directory
xdg-mime query default application/zip
xdg-mime query default application/x-7z-compressed
xdg-mime query default application/x-compressed-tar
nix eval --impure --expr 'let flake = builtins.getFlake "/etc/nixos"; cfg = flake.nixosConfigurations.asura-xs15.config; in builtins.elem "${flake.nixosConfigurations.asura-xs15.pkgs.kdePackages.ark}" cfg.environment.systemPackages'
nix eval /etc/nixos#nixosConfigurations.asura-xs15.config.home-manager.users.asura.wayland.windowManager.hyprland.configType
nix eval --raw /etc/nixos#nixosConfigurations.asura-xs15.config.programs.hyprland.package.version
nix eval --raw /etc/nixos#nixosConfigurations.asura-xs15.config.boot.kernelPackages.kernel.version
nix eval /etc/nixos#nixosConfigurations.asura-xs15.config.boot.initrd.kernelModules
grep -n 'wallpaper = "/etc/nixos/screenshots/lockscreen.png"' /etc/nixos/asura-xs15/noctaliaShell/settings.toml
command -v xdman
command -v xdm-open
command -v codex
command -v asura-screen-record-toggle
asura-screen-record-toggle status
xdg-mime query default x-scheme-handler/xdm-app
xdg-mime query default x-scheme-handler/xdm+app
systemctl --user is-enabled xdman.service || true
systemctl --user is-active xdman.service || true
test -d /opt/xdman/chrome-extension
grep -R -- '--load-extension=/opt/xdman/chrome-extension' \
  ~/.local/share/applications ~/.config/BraveSoftware ~/.config/google-chrome ~/.config/chromium
grep -n 'plugins."github@openai-curated"' ~/.codex/config.toml
grep -n 'plugins."notion@openai-curated"' ~/.codex/config.toml
grep -n 'ai-memory-files' ~/.codex/config.toml
! grep -n 'mcp_servers.ai-memory-sqlite' ~/.codex/config.toml
ai-memory-mcp-status
test -f ~/.config/ai-unified-memory/mcp/config.sqlite-opt-in.json
systemctl --user is-enabled asura-video-wallpaper-battery-guard.timer
systemctl is-enabled libvirtd.service || true
systemctl is-enabled libvirt-guests.service || true
systemctl is-enabled libvirtd.socket
systemctl is-enabled virtlogd.socket
systemctl is-enabled virtlockd.socket
systemctl is-enabled blueman.service || true
vibewall close
vibewall toggle
sleep 1
vibewall close
vibewall wallhaven search "pixel art" --page 1
timeout 8s vibewall picker --wallhaven || test "$?" = 124
vibewall apply /home/asura/Wallpaper/radha-krishna-5120x2880-14416.png
test "$(noctalia msg wallpaper-get)" = "/home/asura/Wallpaper/radha-krishna-5120x2880-14416.png"
timeout 8s vibewall picker --mode grid || test "$?" = 124
vibewall-benchmark
test ! -e /run/current-system/sw/bin/hyprlock
test ! -e /run/current-system/sw/bin/wofi
systemd-analyze
systemd-analyze critical-chain graphical.target
systemd-analyze blame | head -30
systemctl is-enabled nvidia-persistenced.service || true
systemctl is-enabled nvidia-persistenced-delayed.timer
systemctl cat desktop-cache-warm.timer nix-gc.timer nix-optimise.timer
tuned-adm active
```

Expected values:

| Check | Expected |
|---|---|
| Hostname | `asura-xs15` |
| Failed system units | `0 loaded units listed` |
| NBFC selected config | `/etc/nbfc/Colorful X15 AT 22.json` |
| NBFC EC backend | `ec_sys` |
| NBFC fan count | `2` |
| NBFC max speed | `255` for CPU and GPU fans |
| NBFC-GTK | launches and stays alive until timeout; old failure was missing GTK typelibs |
| Directory MIME | `org.gnome.Nautilus.desktop` |
| Archive MIME | `xarchiver.desktop` |
| Archive app ownership | Ark eval returns `false`; Xarchiver is the only archive UI in system packages |
| GNOME color scheme | `prefer-dark` |
| Hyprland config type | `"hyprlang"` |
| Hyprland version | `0.55.3+date=2026-06-07_fe5fe79` |
| Kernel version | `7.0.11` |
| NVIDIA initrd preload | no `nvidia*` modules in `boot.initrd.kernelModules` |
| NVIDIA boot params | no local `nvidia-drm.modeset` or `nvidia-drm.fbdev` in `boot.kernelParams` |
| Lockscreen wallpaper | `/etc/nixos/screenshots/lockscreen.png` |
| XDM scheme handlers | `xdm-app.desktop` |
| XDM browser helper | `/opt/xdman/chrome-extension` exists; Brave/Chrome/Chromium launchers load it |
| XDM browser monitor | `xdman.service` is not enabled at boot; browser extension/protocol handlers remain installed and `xdm-open` starts XDM on demand |
| Screen recorder | `asura-screen-record-toggle` exists; Noctalia left quick-actions and `SUPER+SHIFT+R` call it; `status` shows elapsed state and `toggle-pause` pauses/resumes |
| Codex CLI | `/run/current-system/sw/bin/codex` exists after rebuild |
| Codex plugins | generated `~/.codex/config.toml` keeps GitHub and Notion plugin blocks |
| AI memory MCP | default editor config includes `ai-memory-files`; SQLite MCP is only in opt-in config |
| Video wallpaper battery guard | user timer enabled; `mpvpaper` is suspended on battery |
| VM stack | `libvirtd.service` and `libvirt-guests.service` are not enabled; libvirt sockets are enabled for on-demand VM use |
| Bluetooth tray | base BlueZ stays available; Blueman tray/OBEX service is disabled |
| Vibewall toggle | first `vibewall toggle` starts daemon/picker; close cleans picker |
| Vibewall transparent overlay | active workspace remains visible behind centered toolbar/cards; proof screenshot is `screenshots/vibewallrezero-transparent-overlay.png` |
| Vibewall image apply | `vibewall apply` returns `ok` and `noctalia msg wallpaper-get` returns the requested path |
| Vibewall Wallhaven | cached browser opens immediately; WEB page loading runs in the background; `D`/`DOWNLOAD` saves selected remote wallpaper and `Enter`/`APPLY` downloads then applies |
| Vibewall benchmark | daemon stays small, picker is event-driven at idle |
| Removed launchers | no Hyprlock, no Wofi |
| Boot critical path | `nvidia-persistenced.service` should not gate `graphical.target` after reboot |
| NVIDIA persistence | service disabled for boot pull-in, delayed timer enabled |
| Maintenance timers | `nix-gc.timer` and `nix-optimise.timer` use `Persistent=false` |
| Cache warm | starts after `2min`, has idle scheduling and memory caps |

Fan safety:

```bash
nbfc-colorful-verify
nbfc set -f 0 -s 50
nbfc set -f 1 -s 50
nbfc status
nbfc set -a
```

Only test `100%` briefly and return to auto mode:

```bash
nbfc set -f 0 -s 100
nbfc set -f 1 -s 100
sleep 5
nbfc status
nbfc set -a
```

Known fan readback quirk:

| Fan | Target write | Current-speed readback |
|---|---|---|
| CPU | Verified at `100%` target | Reports `100%` during the brief test |
| GPU | Accepts `100%` target on write register `232` | Can remain negative/low because EC read register `208` is not reliable live |

Before pushing:

```bash
git status --short
git grep -nE '(password|token|secret|api[_-]?key|private key)' -- .
git remote -v
```

Do not commit private keys, raw tokens, browser state, `.env` files, or local
AI memory databases.

Repository target is public:

```bash
gh repo create Valo-Asura/asura-xs15-nixos --public --source=/etc/nixos --remote=origin --push
```
