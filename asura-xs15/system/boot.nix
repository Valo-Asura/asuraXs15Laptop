# Boot Configuration
{ lib, pkgs, ... }:

let
  pkiBundle = "/var/lib/sbctl";
  linuxEspPartUuid = "ea0c3f00-a433-4db6-b494-b982ec40415b";
  windowsEspPartUuid = "00000000-0000-0000-0000-000000000000";
  circleHudPlymouth = pkgs.stdenvNoCC.mkDerivation {
    pname = "circle-hud-plymouth-theme";
    version = "local";
    src = ../backup/plymouth/circle_hud;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      theme_dir="$out/share/plymouth/themes/circle_hud"
      mkdir -p "$theme_dir"
      cp -a . "$theme_dir"

      cat > "$theme_dir/circle_hud.plymouth" <<EOF
      [Plymouth Theme]
      Name=circle_hud
      Description=Asura XS15 local circle HUD boot theme
      Comment=Local declarative copy from /etc/nixos/asura-xs15/backup/plymouth/circle_hud
      ModuleName=script

      [script]
      ImageDir=$theme_dir
      ScriptFile=$theme_dir/circle_hud.script
      EOF

      runHook postInstall
    '';
  };
  preferSignedBootEntry = pkgs.writeShellScript "prefer-signed-boot-entry" ''
    set -u

    if [ ! -d /sys/firmware/efi/efivars ]; then
      exit 0
    fi

    status="$(${pkgs.efibootmgr}/bin/efibootmgr 2>/dev/null || true)"
    if [ -z "$status" ]; then
      exit 0
    fi

    printf '%s\n' "$status" \
      | ${pkgs.gawk}/bin/awk '
        /^Boot[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][* ]/ {
          id = substr($1, 5, 4)
          desc = substr($0, index($0, $2))
          print id "\t" desc
        }
      ' \
      | while IFS="$(printf '\t')" read -r id desc; do
        [ -n "$id" ] || continue

        should_delete=0
        case "$desc" in
          Limine*|UEFI\ OS*|*Atlas*)
            should_delete=1
            ;;
        esac

        if printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -q '^Linux Boot Manager' \
          && ! printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -qi '${linuxEspPartUuid}'; then
          should_delete=1
        fi

        if printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -q '^Windows Boot Manager' \
          && ! printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -qi '${windowsEspPartUuid}'; then
          should_delete=1
        fi

        if [ "$should_delete" = 1 ]; then
          ${pkgs.efibootmgr}/bin/efibootmgr -b "$id" -B || true
        fi
      done

    status="$(${pkgs.efibootmgr}/bin/efibootmgr -v 2>/dev/null || true)"
    linux_entry="$(printf '%s\n' "$status" | ${pkgs.gnugrep}/bin/grep -i "Linux Boot Manager.*${linuxEspPartUuid}" | ${pkgs.gnused}/bin/sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | ${pkgs.coreutils}/bin/head -n1)"
    windows_entry="$(printf '%s\n' "$status" | ${pkgs.gnugrep}/bin/grep -i "Windows Boot Manager.*${windowsEspPartUuid}" | ${pkgs.gnused}/bin/sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | ${pkgs.coreutils}/bin/head -n1)"
    current_order="$(printf '%s\n' "$status" | ${pkgs.gnused}/bin/sed -n 's/^BootOrder: //p' | ${pkgs.coreutils}/bin/head -n1)"

    if [ -z "$linux_entry" ] || [ -z "$current_order" ]; then
      exit 0
    fi

    rest="$(printf '%s\n' "$current_order" \
      | ${pkgs.gawk}/bin/awk -v linux="$linux_entry" -v windows="$windows_entry" '
        BEGIN { RS=","; ORS="" }
        $0 != linux && $0 != windows && $0 != "" {
          if (out != "") out = out ","
          out = out $0
        }
        END { print out }
      ')"

    new_order="$linux_entry"
    if [ -n "$windows_entry" ]; then
      new_order="$new_order,$windows_entry"
    fi
    if [ -n "$rest" ]; then
      new_order="$new_order,$rest"
    fi

    if [ "$new_order" != "$current_order" ]; then
      ${pkgs.efibootmgr}/bin/efibootmgr -o "$new_order" || true
    fi
  '';
in
{
  environment.systemPackages = with pkgs; [
    sbctl
    efibootmgr
    tpm2-tools
  ];

  boot = {
    consoleLogLevel = 4;
    initrd = {
      verbose = true;
      stage1Greeting = "";
    };

    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 12;

      systemd-boot = {
        enable = lib.mkForce true;
        editor = false;
        consoleMode = "max";
        configurationLimit = 8;
        rebootForBitlocker = true;
      };

      grub.enable = false;
      limine.enable = false;
    };

    lanzaboote = {
      enable = false;
      pkiBundle = pkiBundle;
    };

    plymouth = {
      enable = true;
      theme = "circle_hud";
      themePackages = [ circleHudPlymouth ];
    };

    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "splash"
      "loglevel=4"
      "rd.systemd.show_status=true"
      "systemd.show_status=true"
      "rd.udev.log_level=info"
      "udev.log_level=info"
      "vt.global_cursor_default=0"
      "video=eDP-1:1920x1080@144"
      "nowatchdog"
      "nmi_watchdog=0"
      "split_lock_detect=off"
      "cryptomgr.notests"
    ];
  };

  specialisation.rescue-no-nvidia.configuration = {
    boot = {
      plymouth.enable = lib.mkForce false;
      kernelParams = [
        "systemd.unit=multi-user.target"
        "plymouth.enable=0"
        "modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm"
        "rd.systemd.show_status=true"
        "systemd.show_status=true"
        "loglevel=6"
      ];
    };
  };

  system.activationScripts.createSbctlKeys.text = ''
    if [ -f /etc/nixos/enable-sbctl-auto-create ]; then
      if [ ! -d ${pkiBundle} ]; then
        echo "Auto-creating Secure Boot keys (sbctl)..."
        ${pkgs.sbctl}/bin/sbctl create-keys || true
      else
        echo "sbctl key bundle already exists at ${pkiBundle}; skipping creation."
      fi
    fi
  '';

  system.activationScripts.preferSignedBootEntry.text = ''
    ${preferSignedBootEntry}
  '';

  system.activationScripts.syncWindowsBootEntry.text = ''
        windows_esp="/dev/disk/by-partuuid/${windowsEspPartUuid}"
        mount_dir="$(${pkgs.coreutils}/bin/mktemp -d)"

        if [ -d /boot/loader/entries ]; then
          ${pkgs.coreutils}/bin/rm -f /boot/loader/entries/*[Aa]tlas*.conf
        fi

        cleanup() {
          ${pkgs.util-linux}/bin/umount "$mount_dir" >/dev/null 2>&1 || true
          ${pkgs.coreutils}/bin/rmdir "$mount_dir" >/dev/null 2>&1 || true
        }
        trap cleanup EXIT

        if [ -e "$windows_esp" ] && ${pkgs.util-linux}/bin/mount -o ro "$windows_esp" "$mount_dir" >/dev/null 2>&1; then
          if [ -f "$mount_dir/EFI/Microsoft/Boot/bootmgfw.efi" ]; then
            ${pkgs.coreutils}/bin/mkdir -p /boot/EFI/Microsoft /boot/loader/entries
            ${pkgs.coreutils}/bin/rm -rf /boot/EFI/Microsoft/Boot
            ${pkgs.coreutils}/bin/cp -a "$mount_dir/EFI/Microsoft/Boot" /boot/EFI/Microsoft/Boot
            ${pkgs.coreutils}/bin/cat > /boot/loader/entries/windows.conf <<'EOF'
    title Windows Boot Manager
    efi /EFI/Microsoft/Boot/bootmgfw.efi
    sort-key z_windows
    EOF
          fi
        fi
  '';
}
