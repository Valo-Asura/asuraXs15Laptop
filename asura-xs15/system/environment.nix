# Environment Configuration
{ pkgs, ... }:

let
  playwrightBrowsers = pkgs.playwright-driver.browsers.override {
    withFirefox = false;
    withWebkit = false;
  };
in
{
  environment = {
    sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "qt6ct";
      SDL_VIDEODRIVER = "wayland,x11";
      GDK_BACKEND = "wayland,x11";
      GTK_THEME = "adw-gtk3-dark";
      CLUTTER_BACKEND = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_SESSION_CLASS = "user";
      NO_AT_BRIDGE = "0";
      PLAYWRIGHT_BROWSERS_PATH = "${playwrightBrowsers}";
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
      NODE_PATH = "${pkgs.playwright-test}/lib/node_modules";
      CHROME_BIN = "${pkgs.google-chrome}/bin/google-chrome-stable";
      CHROME_PATH = "${pkgs.google-chrome}/bin/google-chrome-stable";
      PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = "${pkgs.google-chrome}/bin/google-chrome-stable";
    };

    variables = {
      CMAKE_PREFIX_PATH = "/run/current-system/sw";
      CPATH = "/run/current-system/sw/include";
    };

    pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
      "/share/dbus-1"
      "/share/gsettings-schemas"
      "/share/icons"
      "/share/pixmaps"
      "/share/gtk-3.0"
      "/share/gtk-4.0"
    ];

    etc."xdg/mime/defaults.list".text = ''
      [Default Applications]
      inode/directory=org.gnome.Nautilus.desktop
      application/zip=xarchiver.desktop
      application/x-zip-compressed=xarchiver.desktop
      application/x-7z-compressed=xarchiver.desktop
      application/x-rar=xarchiver.desktop
      application/vnd.rar=xarchiver.desktop
      application/x-tar=xarchiver.desktop
      application/x-compressed-tar=xarchiver.desktop
      application/x-bzip-compressed-tar=xarchiver.desktop
      application/x-bzip2-compressed-tar=xarchiver.desktop
      application/x-xz-compressed-tar=xarchiver.desktop
      application/x-gzip=xarchiver.desktop
      application/gzip=xarchiver.desktop
      application/x-bzip2=xarchiver.desktop
      application/x-xz=xarchiver.desktop
      application/zstd=xarchiver.desktop
      application/x-lz4=xarchiver.desktop
      application/x-iso9660-image=xarchiver.desktop
    '';
  };
}
