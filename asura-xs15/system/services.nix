# System Services Configuration
{
  pkgs,
  lib,
  ...
}:

{
  systemd.services.mongodb.wantedBy = lib.mkForce [ ];

  # systemd-user can deadlock on this laptop when pam_systemd tries to open a
  # second logind session for the user manager. When it times out, boot waits
  # 90s and nixos-rebuild switch cannot reload user units.
  security.pam.services.systemd-user.startSession = lib.mkForce false;
  systemd.services."user@" = {
    environment.XDG_RUNTIME_DIR = "/run/user/%i";
    serviceConfig.TimeoutStartSec = "25s";
  };

  services = {
    blueman = {
      enable = true;
    };
    dbus = {
      enable = true;
      # dbus-broker reduces desktop service activation latency compared to the classic daemon.
      implementation = "broker";
    };
    fwupd.enable = false; # firmware updater — run manually when needed
    udisks2.enable = true;
    gvfs.enable = true;
    upower.enable = true;
    ratbagd.enable = true;
    mongodb = {
      enable = true;
      bind_ip = "127.0.0.1";
      # mongodb-ce downloads the official upstream pre-built binary.
      # pkgs.mongodb compiles from source (30-60min, OOM kills the desktop).
      package = pkgs.mongodb-ce;
      mongoshPackage = pkgs.mongosh;
      extraConfig = ''
        storage:
          wiredTiger:
            engineConfig:
              cacheSizeGB: 0.25
      '';
    };
    printing.enable = false; # no printer — removes CUPS daemon
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "hyprland"
      "gtk"
    ];
    config.qtile.default = [
      "gtk"
    ];
  };

  security.wrappers."gpu-screen-recorder" = {
    source = "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder";
    owner = "root";
    group = "root";
    setuid = true;
  };

  # Enable dconf for GNOME applications
  programs.dconf.enable = true;

  # Enable accessibility services for desktop shell keyboard input.
  services.gnome.at-spi2-core.enable = true;

  # Compile GSettings schemas properly
  services.dbus.packages = with pkgs; [
    gsettings-desktop-schemas
    gtk3
    gtk4
  ];

  # Systemd User Services
  systemd.user.services.udiskie = {
    description = "Udiskie Daemon";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --no-notify";
      Restart = "always";
      RestartSec = 10;
    };
  };
}
