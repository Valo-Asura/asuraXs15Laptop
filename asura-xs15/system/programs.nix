# Programs Configuration
{
  inputs,
  pkgs,
  ...
}:

let
  hyprlandPackages = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  skwdWall = inputs.skwd-wall.packages.${pkgs.stdenv.hostPlatform.system}.default;
in

{
  programs = {
    # Enable direnv system-wide
    direnv.enable = true;

    # Fish shell (detailed config in home-manager)
    fish.enable = true;

    # Zed downloads ACP agents such as codex-acp as generic Linux binaries.
    # nix-ld provides the dynamic loader path those binaries expect on NixOS.
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        openssl
        curl
        libxcrypt
      ];
    };

    # Track Hyprland's latest stable release package pair explicitly.
    hyprland = {
      enable = true;
      package = hyprlandPackages.hyprland;
      portalPackage = hyprlandPackages.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };

    skwd-wall.enable = true;

    chromium = {
      enable = true;
      extensions = [
        # uBlock Origin for Chromium, Chrome, and Brave policy-managed installs.
        "cjpalhdlnbpafiamejdnhcphjbkeiagm"
      ];
    };

    ssh.startAgent = true;
  };

  systemd.user.services.skwd-daemon = {
    description = "Skwd wallpaper daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    environment.RUST_LOG = "info";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${skwdWall}/bin/skwd-daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
