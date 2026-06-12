# Interactive desktop performance
{ lib, pkgs, ... }:

let
  warmTargets = [
    "${pkgs.brave}/bin/brave"
    "${pkgs.firefox}/bin/firefox"
    "${pkgs.google-chrome}/bin/google-chrome-stable"
    "${pkgs.vscode}/bin/code"
    "${pkgs.kiro}/bin/kiro"
    "${pkgs.nautilus}/bin/nautilus"
    "${pkgs.foot}/bin/foot"
  ];
  desktopCoreProcesses = [
    ".Hyprland-wrapp"
    ".xdg-desktop-po"
    "Hyprland"
    "foot"
    "hyprland"
    "nautilus"
    "nbfc-gtk"
    "noctalia"
    "start-hyprland"
    "vibewall"
    ".vibewall-daemo"
    ".vibewall-picke"
  ];
  interactiveProcesses = [
    ".antigravity-wrapped"
    ".cursor-wrapped"
    ".kiro-wrapped"
    "antigravity"
    "brave"
    "brave-browser"
    "chrome"
    "code"
    "cursor"
    "firefox"
    "firefox-bin"
    "google-chrome"
    "google-chrome-stable"
    "kiro"
  ];
  backgroundProcesses = [
    "cargo"
    "cc1"
    "cc1plus"
    "cmake"
    "gcc"
    "g++"
    "ld"
    "make"
    "meson"
    "ninja"
    "nix"
    "nix-build"
    "nix-daemon"
    "nix-store"
    "nixos-rebuild"
    "rustc"
  ];
  mkRule = type: name: { inherit name type; };
  desktopCacheWarm = pkgs.writeShellScript "desktop-cache-warm" ''
    set -euo pipefail

    min_available_kib=$((10 * 1024 * 1024))
    available_kib="$(${pkgs.gawk}/bin/awk '/MemAvailable/ { print $2 }' /proc/meminfo)"

    if [ -z "$available_kib" ] || [ "$available_kib" -lt "$min_available_kib" ]; then
      exit 0
    fi

    targets=(
      ${lib.concatMapStringsSep "\n      " (target: lib.escapeShellArg target) warmTargets}
    )
    existing=()
    for target in "''${targets[@]}"; do
      [ -e "$target" ] && existing+=("$target")
    done
    [ "''${#existing[@]}" -gt 0 ] || exit 0

    exec ${pkgs.vmtouch}/bin/vmtouch -q -t -f -m 24M "''${existing[@]}"
  '';
in
{
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    settings = {
      apply_cgroup = lib.mkForce false;
      cgroup_load = lib.mkForce false;
      cgroup_realtime_workaround = lib.mkForce false;
    };
    extraTypes = [
      {
        type = "DesktopCore";
        nice = -8;
        ioclass = "best-effort";
        ionice = 0;
        latency_nice = -8;
      }
      {
        type = "InteractiveDesktop";
        nice = -6;
        ioclass = "best-effort";
        ionice = 0;
        latency_nice = -6;
      }
      {
        type = "DesktopHelper";
        nice = 12;
        ioclass = "idle";
        sched = "idle";
        latency_nice = 8;
      }
      {
        type = "BuildBackground";
        nice = 15;
        ioclass = "idle";
        ionice = 7;
        sched = "idle";
        latency_nice = 10;
      }
    ];
    extraRules =
      (map (mkRule "DesktopCore") desktopCoreProcesses)
      ++ (map (mkRule "InteractiveDesktop") interactiveProcesses)
      ++ (map (mkRule "BuildBackground") backgroundProcesses)
      ++ [
        {
          name = "chrome_crashpad_handler";
          type = "DesktopHelper";
        }
        {
          name = "copilot-agent-linux";
          type = "DesktopHelper";
        }
      ];
  };

  systemd.services.desktop-cache-warm = {
    description = "Warm page cache for launch-sensitive desktop apps";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = desktopCacheWarm;
      SuccessExitStatus = [ 0 ];
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
      CPUSchedulingPolicy = "idle";
      CPUWeight = 10;
      IOWeight = 10;
      MemoryHigh = "128M";
      MemoryMax = "384M";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  systemd.timers.desktop-cache-warm = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "desktop-cache-warm.service";
      OnBootSec = "2min";
      OnUnitInactiveSec = "6h";
      AccuracySec = "5min";
      RandomizedDelaySec = "5min";
    };
  };
}
