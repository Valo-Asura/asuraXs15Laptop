{ pkgs, ... }:
let
  terminal = "${pkgs.foot}/bin/foot";
  browser = "${pkgs.brave}/bin/brave";
  editor = "code --ozone-platform=wayland";
  lock = "/run/current-system/sw/bin/noctalia-safe-lock";
in
{
  wayland.windowManager.hyprland = {
    settings = {
      bind = [
        "SUPER, Q, killactive"
        "SUPER, H, exit"
        "SUPER, F, exec, asura-file-manager \"$HOME\""
        "SUPER, G, togglefloating"
        "SUPER, J, layoutmsg, togglesplit"
        "SUPER, B, exec, ${browser}"
        "SUPER, T, exec, ${terminal}"
        "SUPER, C, exec, ${editor}"
        "SUPER, A, exec, noctalia msg panel-toggle launcher"
        "SUPER, E, exec, ${pkgs.telegram-desktop}/bin/telegram-desktop"
        "SUPER, W, exec, vibewall toggle"
        "SUPER, P, exec, asura-display-manager"
        "SUPER SHIFT, P, exec, asura-monitor-guard --restore"
        "CTRL, L, exec, ${lock}"
        "SUPER, L, exec, noctalia msg session lock"
        "SUPER, V, exec, noctalia msg panel-toggle clipboard"
        "SUPER SHIFT, V, togglefloating"
        "SUPER SHIFT, C, exec, clipboard"
        "SUPER SHIFT, E, exec, noctalia msg panel-toggle launcher /emo"
        "SUPER SHIFT, S, exec, noctalia msg screenshot-region"
        "SUPER SHIFT, W, exec, vibewall toggle"
        "SUPER SHIFT, R, exec, /run/current-system/sw/bin/asura-screen-record-toggle"
        "SUPER SHIFT, X, exec, noctalia msg screenshot-region"
        "SUPER, F2, exec, night-shift"
        "SUPER, N, exec, noctalia msg panel-toggle control-center"
        "SUPER, D, exec, noctalia msg panel-toggle control-center"
        "SUPER, I, exec, noctalia msg settings-toggle"
        "CTRL ALT, Delete, exec, noctalia msg session logout"
        "SUPER, BackSpace, exec, noctalia msg panel-toggle session"
        "SUPER, Period, exec, noctalia msg panel-toggle launcher /emo"
        "CTRL SUPER, R, exec, noctalia msg config-reload"
        ", Print, exec, noctalia msg screenshot-region"
        "SUPER, Print, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
        "SUPER SHIFT, Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"
        "ALT, Tab, cyclenext"
        "ALT SHIFT, Tab, cyclenext, prev"
        "SUPER, Tab, cyclenext"
        "SUPER SHIFT, Tab, submap, resize"
      ]
      ++ (builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = i + 1;
          in
          [
            "SUPER, ${toString ws}, workspace, ${toString ws}"
            "SUPER SHIFT, ${toString ws}, movetoworkspace, ${toString ws}"
          ]
        ) 9
      ))
      ++ [
        "SUPER, 0, workspace, 10"
        "SUPER SHIFT, 0, movetoworkspace, 10"
      ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      bindr = [
        "SUPER, SUPER_L, exec, noctalia msg panel-toggle launcher"
      ];

      bindl = [
        ", XF86AudioMute, exec, sound-toggle"
        ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
        ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
        ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
        ", switch:Lid Switch, exec, ${lock}"
        ", F3, exec, noctalia msg volume-mute"
        ", F10, exec, asura-camera-app"
        ", F11, exec, asura-airplane-toggle"
        ", F12, exec, noctalia msg nightlight-force-toggle"
      ];

      bindle = [
        ", XF86AudioRaiseVolume, exec, sound-up"
        ", XF86AudioLowerVolume, exec, sound-down"
        ", XF86MonBrightnessUp, exec, brightness-up"
        ", XF86MonBrightnessDown, exec, brightness-down"
      ];
    };

    submaps.resize.settings = {
      binde = [
        ", right, resizeactive, 30 0"
        ", left, resizeactive, -30 0"
        ", up, resizeactive, 0 -30"
        ", down, resizeactive, 0 30"
      ];
      bind = [
        ", escape, submap, reset"
        "SUPER SHIFT, Tab, submap, reset"
      ];
    };
  };
}
