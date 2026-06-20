# Optional Quickshell profiles for the normal Hyprland session.
{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:

let
  caelestiaSource = ./profiles/caelestia;
  ricelinShellRoot = ./profiles/ricelin;
  dotfilesShellRoot = ./profiles/dotfiles;
  tideIslandSource = ./profiles/tide-island;
  waybarRoot = ../waybar;
  noctaliaPackage = inputs.noctalia.packages.${system}.default;
  hyprlandPackage = config.programs.hyprland.package;

  buildCliStub = pkgs.writeShellScriptBin "caelestia-build-stub" ''
    echo "caelestia-cli is not used while building the Asura Hyprland profile" >&2
    exit 127
  '';

  caelestiaShell = pkgs.callPackage "${caelestiaSource}/nix" {
    rev = "asura-hyprland-local";
    stdenv = pkgs.clangStdenv;
    quickshell = pkgs.quickshell;
    hyprland = hyprlandPackage;
    caelestia-cli = buildCliStub;
    withCli = false;
    extraRuntimeDeps = with pkgs; [
      foot
      grim
      hyprlandPackage
      libnotify
      slurp
      wl-clipboard
      xdg-utils
    ];
  };

  caelestiaCli = pkgs.writeShellApplication {
    name = "caelestia";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      libnotify
      quickshell
    ];
    text = ''
      set -euo pipefail

      config_path="${caelestiaShell}/share/caelestia-shell"
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/wallpaper"
      state_file="$state_dir/path.txt"

      usage() {
        printf '%s\n' \
          'usage:' \
          '  caelestia shell -s' \
          '  caelestia shell -d' \
          '  caelestia shell TARGET FUNCTION [ARGS...]' \
          '  caelestia wallpaper -f PATH' \
          '  caelestia wallpaper -r' >&2
      }

      if [ "$#" -eq 0 ]; then
        usage
        exit 64
      fi

      case "$1" in
        shell)
          shift
          case "''${1:-}" in
            -d|daemon)
              exec ${caelestiaShell}/bin/caelestia-shell
              ;;
            -s|status|show)
              exec qs ipc --any-display -p "$config_path" show
              ;;
          esac

          if [ "$#" -lt 2 ]; then
            usage
            exit 64
          fi

          target="$1"
          function="$2"
          shift 2
          exec qs ipc --any-display -p "$config_path" call "$target" "$function" "$@"
          ;;

        wallpaper)
          shift
          mkdir -p "$state_dir"
          case "''${1:-}" in
            -f|--file|set)
              path="''${2:-}"
              if [ -z "$path" ]; then
                echo "caelestia wallpaper: missing path" >&2
                exit 64
              fi
              printf '%s\n' "$path" > "$state_file"
              notify-send -a caelestia-shell "Wallpaper selected" "$path" 2>/dev/null || true
              ;;
            -p|--preview)
              printf '{}\n'
              ;;
            -r|--random|random)
              walls="''${CAELESTIA_WALLPAPERS_DIR:-$HOME/Pictures/Wallpapers}"
              path="$(
                find "$walls" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null \
                  | shuf -n 1
              )"
              if [ -z "$path" ]; then
                echo "caelestia wallpaper: no wallpapers found in $walls" >&2
                exit 1
              fi
              printf '%s\n' "$path" > "$state_file"
              notify-send -a caelestia-shell "Wallpaper selected" "$path" 2>/dev/null || true
              ;;
            get)
              test -s "$state_file" && cat "$state_file"
              ;;
            *)
              usage
              exit 64
              ;;
          esac
          ;;

        scheme)
          exit 0
          ;;

        record)
          if command -v asura-screen-record-toggle >/dev/null 2>&1; then
            exec asura-screen-record-toggle toggle
          fi
          echo "recording helper is unavailable" >&2
          exit 127
          ;;

        *)
          usage
          exit 64
          ;;
      esac
    '';
  };

  tideIsland = pkgs.stdenv.mkDerivation {
    pname = "tide-island-asura";
    version = "1.0.11-local";
    src = tideIslandSource;

    nativeBuildInputs = with pkgs; [
      cmake
      ninja
      pkg-config
      makeWrapper
      qt6.wrapQtAppsHook
    ];

    buildInputs = with pkgs; [
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtconnectivity
      qt6.qtsvg
      qt6.qtwayland
      quickshell
      systemd
    ];

    propagatedBuildInputs = with pkgs; [
      bluez
      brightnessctl
      cava
      dbus
      hyprlandPackage
      imagemagick
      networkmanager
      pavucontrol
      playerctl
      pulseaudio
      quickshell
      upower
      wireplumber
    ];

    dontWrapQtApps = true;

    cmakeFlags = [
      (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
      (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
    ];

    postInstall = ''
      rm -f $out/bin/tide-island
      makeWrapper ${pkgs.quickshell}/bin/qs $out/bin/tide-island \
        --prefix PATH : "${
          lib.makeBinPath [
            pkgs.bluez
            pkgs.brightnessctl
            pkgs.cava
            pkgs.dbus
            hyprlandPackage
            pkgs.imagemagick
            pkgs.networkmanager
            pkgs.pavucontrol
            pkgs.playerctl
            pkgs.pulseaudio
            pkgs.upower
            pkgs.wireplumber
          ]
        }" \
        --prefix QML2_IMPORT_PATH : "$out/lib/qt6/qml" \
        --prefix QML_IMPORT_PATH : "$out/lib/qt6/qml" \
        --set QUICKSHELL_LYRICS_BACKEND "$out/share/tide-island/bin/lyricsmpris" \
        --add-flags "-p $out/share/tide-island"
    '';

    postFixup = ''
      wrapQtApp $out/bin/tide-island
      wrapQtApp $out/share/tide-island/bin/lyricsmpris
      wrapQtApp $out/share/tide-island/bin/tide-island-setup
    '';

    meta = {
      description = "Tide Island dynamic island Quickshell profile packaged for Asura Hyprland";
      homepage = "https://github.com/enhaoswen/Tide-island";
      license = lib.licenses.unfreeRedistributable;
      mainProgram = "tide-island";
    };
  };

  asuraWaybar = pkgs.writeShellApplication {
    name = "asura-waybar";
    runtimeInputs = with pkgs; [
      coreutils
      hyprlandPackage
      jq
      networkmanagerapplet
      waybar
    ];
    text = ''
      exec waybar \
        -c /etc/xdg/waybar-asura/config.jsonc \
        -s /etc/xdg/waybar-asura/style.css "$@"
    '';
  };

  asuraWaybarSysbar = pkgs.writeShellApplication {
    name = "asura-waybar-sysbar";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      procps
    ];
    text = builtins.readFile "${waybarRoot}/scripts/sysbar.sh";
  };

  asuraWaybarWorkspaces = pkgs.writeShellApplication {
    name = "asura-waybar-workspaces";
    runtimeInputs = [
      hyprlandPackage
      pkgs.jq
    ];
    text = builtins.readFile "${waybarRoot}/scripts/workspaces.sh";
  };

  quickShellSwitch = pkgs.writeShellApplication {
    name = "asura-quickshell-switch";
    runtimeInputs = with pkgs; [
      bluez
      brightnessctl
      coreutils
      gawk
      glib
      gnugrep
      jq
      libnotify
      networkmanager
      pavucontrol
      playerctl
      procps
      python3
      quickshell
      socat
      systemd
      util-linux
      wireplumber
      xdg-utils
    ];
    text =
      builtins.replaceStrings
        [
          "@RICELIN_QUICKSHELL_PATH@"
          "@DOTFILES_QUICKSHELL_PATH@"
          "@CAELESTIA_SHELL_BIN@"
          "@TIDE_ISLAND_BIN@"
          "@ASURA_ISLAND_PATH@"
          "@WAYBAR_BIN@"
          "@NOCTALIA_BIN@"
        ]
        [
          "/etc/xdg/quickshell/ricelin"
          "/etc/xdg/quickshell/dotfiles"
          "${caelestiaShell}/bin/caelestia-shell"
          "${tideIsland}/bin/tide-island"
          "/home/asura/Projects/asura-island-shell"
          "${asuraWaybar}/bin/asura-waybar"
          "${noctaliaPackage}/bin/noctalia"
        ]
        (builtins.readFile ./scripts/asura-quickshell-switch);
  };

  shellLauncher = pkgs.writeShellApplication {
    name = "asura-shell-launcher";
    runtimeInputs =
      (with pkgs; [
        coreutils
        gawk
        gnugrep
        jq
        libnotify
        procps
        quickshell
      ])
      ++ [ hyprlandPackage ];
    text =
      builtins.replaceStrings
        [
          "@CAELESTIA_BIN@"
          "@DOTFILES_QUICKSHELL_PATH@"
          "@RICELIN_QUICKSHELL_PATH@"
          "@TIDE_ISLAND_PATH@"
          "@ASURA_ISLAND_PATH@"
          "@NOCTALIA_BIN@"
        ]
        [
          "${caelestiaCli}/bin/caelestia"
          "/etc/xdg/quickshell/dotfiles"
          "/etc/xdg/quickshell/ricelin"
          "${tideIsland}/share/tide-island"
          "/home/asura/Projects/asura-island-shell"
          "${noctaliaPackage}/bin/noctalia"
        ]
        (builtins.readFile ./scripts/asura-shell-launcher);
  };
in
{
  environment.systemPackages = [
    caelestiaCli
    caelestiaShell
    asuraWaybar
    asuraWaybarSysbar
    asuraWaybarWorkspaces
    pkgs.quickshell
    pkgs.waybar
    quickShellSwitch
    shellLauncher
    tideIsland
  ];

  environment.etc = {
    "xdg/quickshell/caelestia".source = "${caelestiaShell}/share/caelestia-shell";
    "xdg/quickshell/ricelin".source = ricelinShellRoot;
    "xdg/quickshell/dotfiles".source = dotfilesShellRoot;
    "xdg/quickshell/tide-island".source = "${tideIsland}/share/tide-island";
    "xdg/waybar-asura".source = waybarRoot;
  };

  home-manager.users.asura = {
    home.packages = [
      quickShellSwitch
      shellLauncher
      asuraWaybar
      asuraWaybarSysbar
      asuraWaybarWorkspaces
    ];

    systemd.user.services.noctalia.Service.KillMode = lib.mkForce "process";

    xdg.configFile."asura-shell/profiles.txt".text = ''
      noctalia
      caelestia
      ricelin
      dotfiles
      tide-island
      asura-island
      waybar
    '';
  };
}
