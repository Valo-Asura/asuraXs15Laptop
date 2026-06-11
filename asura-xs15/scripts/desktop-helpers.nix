{ pkgs, ... }:

let
  notify = "${pkgs.libnotify}/bin/notify-send";

  asuraFileManager = pkgs.writeShellScriptBin "asura-file-manager" ''
    set -euo pipefail

    target="''${1:-$HOME}"

    if command -v nautilus >/dev/null 2>&1; then
      exec nautilus --new-window "$target"
    fi

    if command -v pcmanfm-qt >/dev/null 2>&1; then
      exec pcmanfm-qt "$target"
    fi

    ${notify} "File manager unavailable" "Install Nautilus or PCManFM-Qt."
  '';

  asuraApplyCursorTheme = pkgs.writeShellScriptBin "asura-apply-cursor-theme" ''
    set -euo pipefail

    theme="Bibata-Modern-Classic"
    size="18"
    if command -v gsettings >/dev/null 2>&1; then
      gsettings set org.gnome.desktop.interface cursor-theme "$theme" || true
      gsettings set org.gnome.desktop.interface cursor-size "$size" || true
    fi

    if command -v hyprctl >/dev/null 2>&1; then
      hyprctl setcursor "$theme" "$size" >/dev/null 2>&1 || true
    fi
  '';

  asuraWallpaperPanel = pkgs.writeShellScriptBin "asura-wallpaper-panel" ''
    set -euo pipefail

    exec noctalia msg panel-toggle wallpaper
  '';

  asuraVideoWallpaper = pkgs.writeShellScriptBin "asura-video-wallpaper" ''
    set -euo pipefail

    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/asura"
    state_file="$state_dir/video-wallpaper"
    wallpaper_dir="''${ASURA_WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
    output="''${ASURA_WALLPAPER_OUTPUT:-*}"

    find_video() {
      ${pkgs.findutils}/bin/find "$wallpaper_dir" -maxdepth 2 -type f \
        \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) \
        2>/dev/null | ${pkgs.coreutils}/bin/head -n 1
    }

    case "''${1:-}" in
      --restore)
        [ -s "$state_file" ] || exit 0
        video="$(${pkgs.coreutils}/bin/cat "$state_file")"
        ;;
      --stop)
        ${pkgs.procps}/bin/pkill -x mpvpaper >/dev/null 2>&1 || true
        ${pkgs.coreutils}/bin/rm -f "$state_file"
        noctalia msg config-reload >/dev/null 2>&1 || true
        exit 0
        ;;
      ""|--pick)
        video="$(find_video)"
        ;;
      *)
        video="$1"
        ;;
    esac

    if [ -z "''${video:-}" ] || [ ! -f "$video" ]; then
      ${notify} "Video wallpaper unavailable" "Add an mp4/webm/mkv/mov under $wallpaper_dir or pass a video path."
      exit 1
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"
    ${pkgs.coreutils}/bin/printf '%s\n' "$video" > "$state_file"
    ${pkgs.procps}/bin/pkill -x mpvpaper >/dev/null 2>&1 || true

    exec ${pkgs.mpvpaper}/bin/mpvpaper \
      --fork \
      --auto-stop \
      --layer background \
      --mpv-options "no-audio loop hwdec=auto-safe profile=fast" \
      "$output" \
      "$video"
  '';

  asuraVideoWallpaperStop = pkgs.writeShellScriptBin "asura-video-wallpaper-stop" ''
    exec asura-video-wallpaper --stop
  '';

  asuraMonitorGuard = pkgs.writeShellScriptBin "asura-monitor-guard" ''
    set -euo pipefail

    case "''${1:-}" in
      --restore)
        hyprctl reload >/dev/null 2>&1 || true
        noctalia msg config-reload >/dev/null 2>&1 || true
        ;;
      --daemon|"")
        exit 0
        ;;
      *)
        echo "usage: asura-monitor-guard [--daemon|--restore]" >&2
        exit 2
        ;;
    esac
  '';

  asuraDisplayManager = pkgs.writeShellScriptBin "asura-display-manager" ''
    set -euo pipefail

    if command -v hyprmod >/dev/null 2>&1; then
      exec hyprmod
    fi

    if command -v nwg-displays >/dev/null 2>&1; then
      exec nwg-displays
    fi

    ${notify} "Display manager unavailable" "Install hyprmod or nwg-displays."
  '';

  asuraAirplaneToggle = pkgs.writeShellScriptBin "asura-airplane-toggle" ''
    set -euo pipefail

    wifi="$(nmcli radio wifi 2>/dev/null || echo unknown)"
    if [ "$wifi" = "enabled" ]; then
      nmcli radio all off || true
      bluetoothctl power off >/dev/null 2>&1 || true
      ${notify} "Airplane mode" "Wireless radios disabled."
    else
      nmcli radio all on || true
      bluetoothctl power on >/dev/null 2>&1 || true
      ${notify} "Airplane mode" "Wireless radios enabled."
    fi
  '';

  asuraCameraApp = pkgs.writeShellScriptBin "asura-camera-app" ''
    set -euo pipefail

    if command -v snapshot >/dev/null 2>&1; then
      exec snapshot
    fi

    if command -v cheese >/dev/null 2>&1; then
      exec cheese
    fi

    ${notify} "Camera app unavailable" "Install GNOME Snapshot or Cheese."
  '';

  clipboard = pkgs.writeShellScriptBin "clipboard" ''
    exec noctalia msg panel-toggle clipboard
  '';

  asuraDarkModeRefresh = pkgs.writeShellScriptBin "asura-dark-mode-refresh" ''
    set -euo pipefail

    dbus-update-activation-environment --systemd \
      DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      XDG_SESSION_TYPE XDG_SESSION_CLASS XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS \
      GTK_THEME >/dev/null 2>&1 || true

    gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark || true
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark || true
  '';
in
{
  home.packages = with pkgs; [
    cheese
    nwg-displays
    snapshot
    asuraAirplaneToggle
    asuraApplyCursorTheme
    asuraCameraApp
    asuraDarkModeRefresh
    asuraDisplayManager
    asuraFileManager
    asuraMonitorGuard
    asuraVideoWallpaper
    asuraVideoWallpaperStop
    asuraWallpaperPanel
    clipboard
  ];
}
