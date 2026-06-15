# KDE Connect plus the Hyprland RemoteDesktop portal bridge needed for
# phone-to-laptop mouse and keyboard control on Wayland.
{
  lib,
  pkgs,
  ...
}:

let
  hyprKdeconnectFix = pkgs.stdenv.mkDerivation rec {
    pname = "hypr-kdeconnect-fix";
    version = "0.1.0-ea55f66";

    src = pkgs.fetchFromGitHub {
      owner = "gfhdhytghd";
      repo = "hypr-kdeconnect-fix";
      rev = "ea55f66c8238235983d60d381bf2abe1fed50043";
      hash = "sha256-OW18+pO92XvlTLrHo+S9/EVUophr5Dl1GdGJcmVAq/o=";
    };

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      qt6.wrapQtAppsHook
      wayland-scanner
    ];

    buildInputs = with pkgs; [
      libei
      libxkbcommon
      qt6.qtbase
      wayland
    ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DHKCF_PORTAL_USE_IN=wlroots;Hyprland;sway;Wayfire;river;phosh;niri;labwc"
    ];

    doCheck = true;

    postInstall = ''
      ln -s "$out/bin/hypr-kdeconnect-portal" "$out/bin/hypr-kdeconnect-fix"
    '';

    meta = {
      description = "RemoteDesktop portal bridge for KDE Connect remote input on Hyprland";
      homepage = "https://github.com/gfhdhytghd/hypr-kdeconnect-fix";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "hypr-kdeconnect-portal";
    };
  };
in
{
  programs.kdeconnect = {
    enable = true;
    package = pkgs.kdePackages.kdeconnect-kde;
  };

  environment.systemPackages = [
    hyprKdeconnectFix
  ];

  # The default portal stack remains Hyprland/GTK. Only RemoteDesktop is routed
  # to the KDE Connect bridge so screenshots, screencasts, file chooser, and
  # global shortcuts keep using their normal backends.
  xdg.portal = {
    extraPortals = [
      hyprKdeconnectFix
    ];
    config.common."org.freedesktop.impl.portal.RemoteDesktop" = [
      "hypr-kdeconnect"
    ];
  };

  systemd.user.services.hypr-kdeconnect-portal = {
    description = "KDE Connect RemoteDesktop portal backend for Hyprland";
    partOf = [ "xdg-desktop-portal.service" ];
    serviceConfig = {
      Type = "dbus";
      BusName = "org.freedesktop.impl.portal.desktop.hypr_kdeconnect";
      ExecStart = "${hyprKdeconnectFix}/bin/hypr-kdeconnect-portal";
      Restart = "on-failure";
      RestartSec = "1s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_UNIX";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
    };
  };
}
