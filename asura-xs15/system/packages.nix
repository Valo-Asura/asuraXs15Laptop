# System Packages Configuration
{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  whatsappWeb = pkgs.writeShellScriptBin "whatsapp-web" ''
    exec ${pkgs.google-chrome}/bin/google-chrome-stable \
      --app=https://web.whatsapp.com \
      --class=whatsapp-web \
      "$@"
  '';

  whatsappWebDesktop = pkgs.makeDesktopItem {
    name = "whatsapp-web";
    desktopName = "WhatsApp";
    genericName = "Messaging";
    comment = "Open WhatsApp Web";
    exec = "whatsapp-web";
    icon = "whatsapp";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    startupWMClass = "whatsapp-web";
  };

  antigravityWithPlaywright = pkgs.symlinkJoin {
    name = "antigravity-with-playwright";
    paths = [ pkgs.antigravity ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      playwright_browsers="${
        pkgs.playwright-driver.browsers.override {
          withFirefox = false;
          withWebkit = false;
        }
      }"
      rm "$out/bin/antigravity"
      makeWrapper ${pkgs.antigravity}/bin/antigravity "$out/bin/antigravity" \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.playwright-test
            pkgs.nodejs
            pkgs.chromium
            pkgs.google-chrome
          ]
        } \
        --prefix NODE_PATH : ${pkgs.playwright-test}/lib/node_modules \
        --set PLAYWRIGHT_BROWSERS_PATH "$playwright_browsers" \
        --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD 1 \
        --set CHROME_BIN ${pkgs.google-chrome}/bin/google-chrome-stable \
        --set CHROME_PATH ${pkgs.google-chrome}/bin/google-chrome-stable \
        --set CHROME_EXECUTABLE ${pkgs.google-chrome}/bin/google-chrome-stable \
        --set PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH ${pkgs.google-chrome}/bin/google-chrome-stable
    '';
  };

  mysqlLocalInfo = pkgs.writeShellScriptBin "mysql-local-info" ''
    cat <<'EOF'
    MySQL local service
      service: systemctl status mysql
      cli:     mysql -u asura asura_dev
      shell:   mysqlsh --sql asura@localhost:3306
      gui:     mysql-workbench

    Paths
      config:  /etc/my.cnf
      data:    /var/lib/mysql
      socket:  /run/mysqld/mysqld.sock
      binary:  /run/current-system/sw/bin/mysql
    EOF
  '';

  vimWrapped = pkgs.vim-full.customize {
    name = "vim";
    vimrcConfig.customRC = ''
      set number
      set relativenumber
      set expandtab
      set shiftwidth=2
      set tabstop=2
      syntax on
    '';
  };

  xdmanRuntimeLibs = with pkgs; [
    atk
    cairo
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libayatana-appindicator
    libnotify
    librsvg
    lttng-ust_2_12
    openssl
    pango
    stdenv.cc.cc.lib
    zlib
    libx11
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
  ];

  xdmanGtk = pkgs.stdenvNoCC.mkDerivation {
    pname = "xdman-gtk";
    version = "8.0.29";

    src = pkgs.fetchurl {
      url = "https://github.com/subhra74/xdm/releases/download/8.0.29/xdman_gtk_8.0.29_amd64.deb";
      hash = "sha256-Nlm7LbAlHI3w+lAeUxhf0Dx7Fde1jCKitguTFEtrnhE=";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      dpkg
      makeWrapper
    ];

    buildInputs = xdmanRuntimeLibs;

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x "$src" source
      runHook postUnpack
    '';

    installPhase = ''
            runHook preInstall

            mkdir -p "$out"
            cp -a source/opt "$out/"
            mkdir -p "$out/share"
            cp -a source/usr/share/. "$out/share/"

            mkdir -p "$out/bin"
            rm -f "$out/bin/xdman"
            makeWrapper "$out/opt/xdman/xdm-app" "$out/bin/xdman" \
              --set GTK_USE_PORTAL 1 \
              --set GDK_PIXBUF_MODULE_FILE "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
              --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath xdmanRuntimeLibs}"

            substituteInPlace "$out/share/applications/xdm-app.desktop" \
              --replace-fail "env GTK_USE_PORTAL=1 /opt/xdman/xdm-app" "$out/bin/xdman" \
              --replace-fail "/opt/xdman/xdm-logo.svg" "$out/opt/xdman/xdm-logo.svg"
            substituteInPlace "$out/share/applications/xdm-app.desktop" \
              --replace-fail "MimeType=application/xdm-app;x-scheme-handler/xdm-app;" \
              "MimeType=application/xdm-app;x-scheme-handler/xdm-app;x-scheme-handler/xdm+app;"
            substituteInPlace "$out/share/applications/xdm-app.desktop" \
              --replace-fail "Categories=Network;" "Categories=Network;FileTransfer;GTK;" \
              --replace-fail "StartupNotify=true" "StartupNotify=false"
      printf '%s\n' \
        'StartupWMClass=xdm-app' \
        'DBusActivatable=false' \
        >> "$out/share/applications/xdm-app.desktop"
            mkdir -p "$out/share/pixmaps"
            ln -sf "$out/opt/xdman/xdm-logo.svg" "$out/share/pixmaps/xdm-logo.svg"

            runHook postInstall
    '';

    meta = {
      description = "Xtreme Download Manager GTK desktop application";
      homepage = "https://github.com/subhra74/xdm";
      license = lib.licenses.gpl2Plus;
      platforms = [ "x86_64-linux" ];
      mainProgram = "xdman";
    };
  };

  # Smart launcher: kills any running xdm-app first, then starts fresh.
  # Needed because a second instance always segfaults on Wayland (GTK
  # gtk_widget_get_scale_factor single-instance mutex bug in xdm 8.0.29).
  xdmOpen = pkgs.writeShellScriptBin "xdm-open" ''
    set -euo pipefail
    # Stop the systemd service so it doesn't restart immediately
    systemctl --user stop xdman.service 2>/dev/null || true
    # Kill any lingering process
    pkill -x xdm-app 2>/dev/null || true
    sleep 0.3
    # Pass any URL/file arguments through (for browser-extension integration)
    exec ${xdmanGtk}/bin/xdman "$@"
  '';

  hyprmod = pkgs.callPackage ./hyprmod.nix { };
in
{
  environment.systemPackages =
    (with pkgs; [
      # System Info & Terminal
      zsh

      # System Tools
      polkit
      udisks2
      udiskie

      # Screenshot and Screen Recording
      grimblast
      hyprshot
      swappy # Screenshot editor

      # Polkit Agent
      inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default

      # File Management & NTFS Support
      xarchiver
      nautilus
      gnome-disk-utility
      pcmanfm-qt
      gvfs
      ntfs3g
      exfat # Windows filesystem support

      # Desktop Environment
      xdg-utils
      networkmanager
      tuigreet
      xdg-user-dirs # xdg-desktop-portals in services.nix

      # Desktop shell support and rollback helpers.
      (writeShellScriptBin "internet-unblock" "")
      dconf
      gtk3
      gtk4
      adw-gtk3
      adwaita-icon-theme
      hicolor-icon-theme
      papirus-icon-theme
      kdePackages.breeze-icons
      gsettings-desktop-schemas
      at-spi2-atk
      at-spi2-core
      libgtop
      loupe
      kdePackages.okular
      sushi

      # Multimedia
      mpv
      vlc
      easyeffects
      freetube
      kdePackages.kdenlive
      obs-studio
      alsa-utils
      pavucontrol
      pulseaudio
      pwvucontrol
      v4l-utils

      # Hyprland Panel Dependencies
      bluez
      hyprsunset
      hypridle
      wl-clipboard
      cliphist
      libnotify
      hyprpicker
      wf-recorder
      cava
      matugen
      mpvpaper
      songrec
      zenity
      qt6Packages.qt6ct
      libsForQt5.qt5ct
      libsForQt5.qtstyleplugin-kvantum
      qt6Packages.qtstyleplugin-kvantum
      nwg-look

      # Development
      wget
      git
      gh
      codex
      jq
      ripgrep
      nixfmt
      nil
      nixd
      uv
      inter
      sops
      docker
      docker-compose
      nodejs
      playwright-test
      playwright-driver
      chromium
      mysql-shell
      mysql-workbench
      mysqlLocalInfo
      mongosh
      mongodb-tools

      # IDE & Editor
      neovim
      vscode
      antigravityWithPlaywright
      (pkgs.callPackage ./cursor.nix { })
      zed-editor
      vimWrapped
      inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Hyprland Tools
      hyprmod
      hyprsysteminfo
      hyprshutdown

      # Desktop apps
      whatsappWeb
      whatsappWebDesktop
      xdmanGtk
      xdmOpen
      piper # Linux GUI for Logitech G304/G305 DPI and button profiles
      solaar # Logitech receiver and wireless device manager
      mongodb-compass
      telegram-desktop
      ani-cli

      # Terminal enhancements
      btop
      tree
      curl
      yq

      # Python Environment
      (python3.withPackages (
        ps: with ps; [
          pip
          requests
        ]
      ))
    ])
    ++ lib.optionals (builtins.hasAttr "windsurf" pkgs) [
      pkgs.windsurf
    ];

  systemd.tmpfiles.rules = [
    "L+ /opt/xdman - - - - ${xdmanGtk}/opt/xdman"
  ];

  systemd.user.services.xdman = {
    description = "Xtreme Download Manager desktop bridge";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;
    };
    serviceConfig = {
      ExecStart = "${xdmanGtk}/bin/xdman";
      Restart = "on-failure";
      RestartSec = 15;
      Environment = "GDK_PIXBUF_MODULE_FILE=${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };
  };
}
