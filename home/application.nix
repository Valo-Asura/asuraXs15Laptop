# File Manager, archive, and viewer defaults
{ lib, ... }:

let
  xarchiver = "xarchiver.desktop";
  nautilus = "org.gnome.Nautilus.desktop";
  loupe = "org.gnome.Loupe.desktop";
  okular = "org.kde.okular.desktop";
  pcmanfmQtSettings = ''
    [Behavior]
    AutoSelectionDelay=600
    BookmarkOpenMethod=current_tab
    ConfirmDelete=true
    ConfirmTrash=false
    NoUsbTrash=false
    RecentFilesNumber=0
    SingleClick=false
    SingleWindowMode=false
    UseTrash=true

    [Desktop]
    BgColor=#191724
    FgColor=#e0def4
    HideItems=false
    ShadowColor=#000000
    ShowHidden=true
    SortColumn=name
    SortFolderFirst=true
    SortHiddenLast=false
    SortOrder=ascending

    [FolderView]
    BigIconSize=48
    Mode=icon
    ScrollPerPixel=true
    ShadowHidden=true
    ShowFilter=false
    ShowFullNames=true
    ShowHidden=true
    SidePaneIconSize=24
    SmallIconSize=24
    SortCaseSensitive=false
    SortColumn=name
    SortFolderFirst=true
    SortHiddenLast=false
    SortOrder=ascending
    ThumbnailIconSize=128

    [Places]
    HiddenPlaces=@Invalid()

    [Search]
    MaxSearchHistory=0
    searchContentCaseInsensitive=false
    searchContentRegexp=true
    searchNameCaseInsensitive=false
    searchNameRegexp=true
    searchRecursive=false
    searchhHidden=true

    [System]
    Archiver=xarchiver
    FallbackIconThemeName=Papirus-Dark
    OnlyUserTemplates=false
    SIUnit=false
    Terminal=foot

    [Thumbnail]
    MaxExternalThumbnailFileSize=-1
    MaxThumbnailFileSize=4096
    ShowThumbnails=false
    ThumbnailLocalFilesOnly=true

    [Volume]
    AutoRun=true
    CloseOnUnmount=true
    MountOnStartup=true
    MountRemovable=true

    [Window]
    AlwaysShowTabs=true
    PathBarButtons=true
    RememberWindowSize=true
    ReopenLastTabs=false
    ShowMenuBar=true
    ShowTabClose=true
    SidePaneMode=places
    SidePaneVisible=true
    SplitView=false
    SidePaneIconSize=24
    SplitterPos=180
  '';

  archiveDefaults = {
    "application/zip" = xarchiver;
    "application/x-zip-compressed" = xarchiver;
    "application/x-7z-compressed" = xarchiver;
    "application/x-rar" = xarchiver;
    "application/vnd.rar" = xarchiver;
    "application/x-tar" = xarchiver;
    "application/x-compressed-tar" = xarchiver;
    "application/x-bzip-compressed-tar" = xarchiver;
    "application/x-bzip2-compressed-tar" = xarchiver;
    "application/x-xz-compressed-tar" = xarchiver;
    "application/x-gzip" = xarchiver;
    "application/gzip" = xarchiver;
    "application/x-bzip2" = xarchiver;
    "application/x-xz" = xarchiver;
    "application/zstd" = xarchiver;
    "application/x-lz4" = xarchiver;
    "application/x-iso9660-image" = xarchiver;
  };

  viewerDefaults = {
    "image/jpeg" = loupe;
    "image/jpg" = loupe;
    "image/png" = loupe;
    "image/gif" = loupe;
    "image/webp" = loupe;
    "image/avif" = loupe;
    "image/svg+xml" = loupe;

    "application/pdf" = lib.mkForce okular;
    "application/epub+zip" = okular;
    "application/postscript" = okular;
    "image/vnd.djvu" = okular;

    "audio/mpeg" = "mpv.desktop";
    "audio/flac" = "mpv.desktop";
    "audio/ogg" = "mpv.desktop";
    "audio/wav" = "mpv.desktop";
    "video/mp4" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
  };

  desktopDefaults =
    archiveDefaults
    // viewerDefaults
    // {
      "inode/directory" = nautilus;
      "x-scheme-handler/steam" = "steam.desktop";
      "x-scheme-handler/steamlink" = "steam.desktop";
    };
in
{
  xdg.dataFile."applications/steam.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=Steam
      GenericName=Game launcher
      Comment=Launch Steam with the same capability-clean wrapper used by the terminal
      Exec=/run/current-system/sw/bin/steam-safe %U
      TryExec=/run/current-system/sw/bin/steam-safe
      Icon=steam
      Terminal=false
      Type=Application
      Categories=Network;FileTransfer;Game;
      MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
      StartupWMClass=steam
      PrefersNonDefaultGPU=true
      X-KDE-RunOnDiscreteGpu=true
    '';
  };

  xdg.dataFile."applications/Counter-Strike 2.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=Counter-Strike 2
      Comment=Play Counter-Strike 2 on Steam
      Exec=/run/current-system/sw/bin/steam-safe steam://rungameid/730
      Icon=steam_icon_730
      Terminal=false
      Type=Application
      Categories=Game;
      StartupWMClass=cs2
    '';
  };

  xdg.dataFile."applications/org.gnome.Nautilus.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=Files
      Comment=Access and organize files
      Exec=nautilus --new-window %U
      TryExec=nautilus
      DBusActivatable=false
      Terminal=false
      Type=Application
      StartupNotify=true
      Categories=GNOME;GTK;Utility;Core;FileManager;
      MimeType=inode/directory;application/x-gnome-saved-search;
      StartupWMClass=org.gnome.Nautilus
      X-GNOME-UsesNotifications=true
    '';
  };

  xdg.dataFile."applications/org.gnome.Nautilus.Admin.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=Files (Admin)
      Comment=Open a root-owned file view through GVFS admin
      Exec=nautilus admin:///
      TryExec=nautilus
      DBusActivatable=false
      Terminal=false
      Type=Application
      StartupNotify=true
      Categories=GNOME;GTK;Utility;Core;FileManager;
      StartupWMClass=org.gnome.Nautilus
    '';
  };

  xdg.dataFile."applications/pcmanfm-qt-admin.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=PCManFM-Qt (Admin)
      Comment=Open PCManFM-Qt with a polkit prompt
      Exec=/home/asura/.local/bin/pcmanfm-qt-admin %U
      TryExec=/home/asura/.local/bin/pcmanfm-qt-admin
      Terminal=false
      Type=Application
      StartupNotify=true
      Categories=Qt;Utility;Core;FileManager;
      StartupWMClass=pcmanfm-qt
    '';
  };

  xdg.dataFile."applications/xdman.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=Xtreme Download Manager
      GenericName=Download Manager
      Comment=Open Xtreme Download Manager
      Exec=xdm-open %U
      TryExec=xdman
      Icon=xdm-logo
      Terminal=false
      Categories=Network;FileTransfer;GTK;
      MimeType=application/xdm-app;x-scheme-handler/xdm-app;x-scheme-handler/xdm+app;
      StartupNotify=false
      StartupWMClass=xdm-app
      DBusActivatable=false
    '';
  };

  xdg.dataFile."applications/xdm-app.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=XDM
      GenericName=Download Manager
      Comment=Open Xtreme Download Manager
      Exec=xdm-open %U
      TryExec=xdman
      Icon=xdm-logo
      Terminal=false
      Categories=Network;FileTransfer;GTK;
      MimeType=application/xdm-app;x-scheme-handler/xdm-app;x-scheme-handler/xdm+app;
      StartupNotify=false
      StartupWMClass=xdm-app
      DBusActivatable=false
    '';
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = desktopDefaults;
    associations.added = desktopDefaults;
  };

  # Ensure existing mimeapps.list is overwritten without backup conflicts
  xdg.configFile."mimeapps.list".force = true;

  xdg.configFile."pcmanfm-qt/default/settings.conf".text = pcmanfmQtSettings;
  xdg.configFile."pcmanfm-qt/lxqt/settings.conf".text = pcmanfmQtSettings;

  xdg.configFile."libfm/libfm.conf".text = ''
    [config]
    single_click=0
    use_trash=1
    confirm_del=1
    terminal=foot

    [ui]
    show_hidden=1
  '';

  home.file.".local/share/nautilus/scripts/Open Archive with Xarchiver" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      selected="''${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}"
      if [ -z "$selected" ]; then
        selected="''${NAUTILUS_SCRIPT_CURRENT_URI:-.}"
      fi
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        xarchiver "$path" >/dev/null 2>&1 &
      done <<< "$selected"
    '';
  };

  home.file.".local/share/nautilus/scripts/Open Current Folder as Admin" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      target="''${NAUTILUS_SCRIPT_CURRENT_URI:-admin:///}"
      case "$target" in
        file://*) exec nautilus "admin://''${target#file://}" ;;
        /*) exec nautilus "admin://$target" ;;
        *) exec nautilus admin:/// ;;
      esac
    '';
  };

  home.file.".local/bin/pcmanfm-qt-admin" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec pkexec env \
        DISPLAY="''${DISPLAY:-}" \
        WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-}" \
        XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-}" \
        DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-}" \
        XAUTHORITY="''${XAUTHORITY:-}" \
        pcmanfm-qt "$@"
    '';
  };

  # Xarchiver is the single archive UI; Nautilus and PCManFM-Qt both route to it.
  home.file.".config/xarchiver/xarchiverrc".text = ''
    [xarchiver]
    preferred_format=0
    prefer_unzip=true
    confirm_deletion=true
    sort_filename_content=false
    advanced_isearch=true
    auto_expand=true
    store_output=false
    icon_size=2
    show_archive_comment=false
    show_sidebar=true
    show_location_bar=true
    show_toolbar=true
    preferred_custom_cmd=
    preferred_temp_dir=/tmp
    preferred_extract_dir=.
    allow_sub_dir=0
    extended_dnd=1
    ensure_directory=true
    overwrite=false
    full_path=2
    touch=false
    fresh=false
    update=false
    store_path=false
    updadd=true
    freshen=false
    recurse=true
    solid_archive=false
    remove_files=false
  '';
}
