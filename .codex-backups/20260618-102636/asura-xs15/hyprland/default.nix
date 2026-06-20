# Hyprland desktop configuration for Asura XS15.
{
  pkgs,
  lib,
  ...
}:
let
  border-size = 1;
  gaps-in = 2;
  gaps-out = 6;
  active-opacity = 1.0;
  inactive-opacity = 1.0;
  rounding = 6;
  blur = false;
  keyboardLayout = "us";
  border-color = "rgb(b4befe)";
  primaryMonitor = "eDP-1";
  primaryMonitorDesc = "eDP-1";
  primaryMode = "1920x1080@144";

  startupCommands = [
    "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE XDG_SESSION_CLASS XDG_SESSION_ID XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS"
    "kdeconnectd"
    "vibewall restore"
    "asura-apply-cursor-theme"
    "asura-monitor-guard --daemon"
    "easyeffects --gapplication-service"
    "nautilus --gapplication-service"
  ];

  # Old hand-written Lua config paths. These are not active config; Home
  # Manager removes stale store symlinks so Hyprland reads hyprland.conf.
  staleLuaFiles = [
    "hyprland.lua"
    "hyprland-gui.lua"
    "noctalia.lua"
    "configs/animations.lua"
    "configs/env.lua"
    "configs/general.lua"
    "configs/hyprexpo.lua"
    "configs/keybinds.lua"
    "configs/monitors.lua"
    "configs/rules.lua"
  ];
in
{
  imports = [
    ./animations.nix
    ./bindings.nix
    ./polkitagent.nix
    ./hypridle.nix
  ];

  home.packages = with pkgs; [
    brightnessctl
    libva
    qt6.qtwayland
    wayland-utils
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    # Reuse the package pair from the NixOS module so Hyprland and XDPH stay in sync.
    package = null;
    portalPackage = null;
    plugins = [ ];
    xwayland.enable = true;
    systemd = {
      enable = true;
      enableXdgAutostart = true;
      variables = [
        "DISPLAY"
        "HYPRLAND_INSTANCE_SIGNATURE"
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP"
        "XDG_SESSION_DESKTOP"
        "XDG_SESSION_TYPE"
        "XDG_SESSION_CLASS"
        "XDG_RUNTIME_DIR"
        "DBUS_SESSION_BUS_ADDRESS"
      ];
    };

    settings = {
      monitor = [
        "desc:${primaryMonitorDesc},${primaryMode},0x0,1"
        "${primaryMonitor},${primaryMode},0x0,1"
        ",preferred,auto,1"
      ];

      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SESSION_CLASS,user"
        "LANG,en_US.UTF-8"
        "MOZ_ENABLE_WAYLAND,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        # NVIDIA/EGL/GBM vendor vars intentionally stay out of compositor env.
        "SDL_VIDEODRIVER,wayland,x11"
        "CLUTTER_BACKEND,wayland"
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Amber"
        "HYPRCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,Bibata-Modern-Amber"
      ];

      "exec-once" = startupCommands;

      cursor = {
        default_monitor = primaryMonitor;
        no_hardware_cursors = 1;
        inactive_timeout = 0;
        enable_hyprcursor = true;
        sync_gsettings_theme = true;
      };

      general = {
        resize_on_border = true;
        gaps_in = gaps-in;
        gaps_out = gaps-out;
        border_size = border-size;
        layout = "master";
        "col.active_border" = border-color;
      };

      decoration = {
        active_opacity = active-opacity;
        inactive_opacity = inactive-opacity;
        rounding = rounding;
        shadow.enabled = false;
        blur = {
          enabled = blur;
          size = 3;
          passes = 1;
          new_optimizations = true;
        };
      };

      master = {
        new_status = "master";
        allow_small_split = true;
        mfact = 0.5;
      };

      debug.vfr = true;

      misc = {
        vrr = 1;
        animate_manual_resizes = false;
        animate_mouse_windowdragging = false;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        focus_on_activate = true;
        enable_swallow = false;
        swallow_regex = "";
      };

      render.direct_scanout = 0;

      input = {
        kb_layout = keyboardLayout;
        kb_options = "caps:escape";
        follow_mouse = 1;
        sensitivity = 0.5;
        repeat_delay = 300;
        repeat_rate = 50;
        numlock_by_default = true;

        touchpad = {
          natural_scroll = true;
          tap_button_map = "lrm";
          clickfinger_behavior = false;
        };
      };

      gesture = [
        "3, horizontal, workspace"
      ];

      windowrule = [
        "float title:^(.*(Open File|Choose Files|File Upload|Save As|Library).*)$, center title:^(.*(Open File|Choose Files|File Upload|Save As|Library).*)$, size 900 600 title:^(.*(Open File|Choose Files|File Upload|Save As|Library).*)$"
        "float title:^(.*(Authentication Required|PolicyKit1).*)$, center title:^(.*(Authentication Required|PolicyKit1).*)$, size 500 400 title:^(.*(Authentication Required|PolicyKit1).*)$"
        "float class:^(polkit-gnome-authentication-agent-1|hyprpolkitagent|polkit-kde-authentication-agent-1)$, center class:^(polkit-gnome-authentication-agent-1|hyprpolkitagent|polkit-kde-authentication-agent-1)$, size 500 400 class:^(polkit-gnome-authentication-agent-1|hyprpolkitagent|polkit-kde-authentication-agent-1)$"
        "float class:^(org\\.kde\\.ark|ark|file-roller|org\\.gnome\\.FileRoller|xarchiver)$, center class:^(org\\.kde\\.ark|ark|file-roller|org\\.gnome\\.FileRoller|xarchiver)$, size 860 620 class:^(org\\.kde\\.ark|ark|file-roller|org\\.gnome\\.FileRoller|xarchiver)$"
        "float class:^(org\\.gnome\\.Nautilus|nautilus)$, center class:^(org\\.gnome\\.Nautilus|nautilus)$, size 1100 740 class:^(org\\.gnome\\.Nautilus|nautilus)$"
        "float class:^(org\\.gnome\\.Loupe|loupe|org\\.kde\\.gwenview|Gwenview)$, center class:^(org\\.gnome\\.Loupe|loupe|org\\.kde\\.gwenview|Gwenview)$, size 980 720 class:^(org\\.gnome\\.Loupe|loupe|org\\.kde\\.gwenview|Gwenview)$"
        "float class:^(org\\.gnome\\.NautilusPreviewer|sushi)$, center class:^(org\\.gnome\\.NautilusPreviewer|sushi)$, size 900 640 class:^(org\\.gnome\\.NautilusPreviewer|sushi)$"
        "float class:^(asura-system-monitor|io\\.missioncenter\\.MissionCenter)$, center class:^(asura-system-monitor|io\\.missioncenter\\.MissionCenter)$, size 980 720 class:^(asura-system-monitor|io\\.missioncenter\\.MissionCenter)$"
        "float class:^(asura-display-manager|hyprmod|nwg-displays|wdisplays)$, center class:^(asura-display-manager|hyprmod|nwg-displays|wdisplays)$, size 1040 720 class:^(asura-display-manager|hyprmod|nwg-displays|wdisplays)$"
        "float class:^(Cloudflare Warp|cloudflare-warp|warp-taskbar|Warp)$, center class:^(Cloudflare Warp|cloudflare-warp|warp-taskbar|Warp)$, size 760 940 class:^(Cloudflare Warp|cloudflare-warp|warp-taskbar|Warp)$, suppress_event maximize class:^(Cloudflare Warp|cloudflare-warp|warp-taskbar|Warp)$"
        "float title:^(Cloudflare Warp|Warp Taskbar|Warp)$, center title:^(Cloudflare Warp|Warp Taskbar|Warp)$, size 760 940 title:^(Cloudflare Warp|Warp Taskbar|Warp)$, suppress_event maximize title:^(Cloudflare Warp|Warp Taskbar|Warp)$"
        "float class:^(xdg-desktop-portal-.*)$, center class:^(xdg-desktop-portal-.*)$, size 900 600 class:^(xdg-desktop-portal-.*)$"
      ];

      layerrule = [
        "match:namespace notifications, blur 1, ignore_alpha 0.69"
        "match:namespace control-center, no_anim 1, blur 1, ignore_alpha 0.5"
        "match:namespace launcher, no_anim 1, blur 1, ignore_alpha 0.5"
        "match:namespace overview, no_anim 1"
        "match:namespace session, blur 1"
        "match:namespace ^ags-.*$, no_anim 1"
      ];
    };
  };

  services.hyprpaper.enable = false;

  home.activation.removeStaleHyprlandLua = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for stale in ${
      lib.concatMapStringsSep " " (name: ''"$HOME/.config/hypr/${name}"'') staleLuaFiles
    }; do
      if [ -L "$stale" ] && ${pkgs.coreutils}/bin/readlink "$stale" | ${pkgs.gnugrep}/bin/grep -q '^/nix/store/'; then
        ${pkgs.coreutils}/bin/rm -f "$stale"
      fi
    done
  '';

  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
}
