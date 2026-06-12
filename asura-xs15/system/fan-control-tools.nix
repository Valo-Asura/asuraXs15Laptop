# NBFC fan control for the Colorful XS 22 / X15 XS laptop.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  modelConfigPath = "/etc/nbfc/Colorful X15 AT 22.json";

  nbfcLinux = pkgs.nbfc-linux.overrideAttrs (_old: {
    version = "0.5.2";
    src = pkgs.fetchFromGitHub {
      owner = "nbfc-linux";
      repo = "nbfc-linux";
      tag = "0.5.2";
      hash = "sha256-468/dFRjEgyJ0AW98wKq04WKZ4sZyzswBASSF6hyjVY=";
    };
    nativeBuildInputs = with pkgs; [
      autoreconfHook
      pkg-config
    ];
    buildInputs = with pkgs; [
      curl
      libxml2
      lua5_4
      openssl
    ];
    configureFlags = [
      "--prefix=${placeholder "out"}"
      "--sysconfdir=${placeholder "out"}/etc"
      "--bindir=${placeholder "out"}/bin"
      "--with-init-system=systemd"
    ];
  });

  pythonWithGtk = pkgs.python3.withPackages (ps: [
    ps.pygobject3
  ]);

  gtkTypelibPath = lib.makeSearchPath "lib/girepository-1.0" (
    map lib.getLib [
      pkgs.gtk4
      pkgs.glib
      pkgs.gdk-pixbuf
      pkgs.pango
      pkgs.graphene
      pkgs.cairo
      pkgs.harfbuzz
      pkgs.gobject-introspection
    ]
  );

  nbfcGtk = pkgs.stdenvNoCC.mkDerivation {
    pname = "nbfc-gtk";
    version = "0.4.1";

    src = pkgs.fetchFromGitHub {
      owner = "nbfc-linux";
      repo = "nbfc-gtk";
      tag = "0.4.1";
      hash = "sha256-2ko957V5SqhnxdZxtbkjMsHbvThag55divZlftrWgRI=";
    };

    nativeBuildInputs = with pkgs; [
      makeWrapper
      pythonWithGtk
      wrapGAppsHook4
    ];

    buildInputs = with pkgs; [
      gtk4
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      make nbfc-gtk.py
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 nbfc-gtk.py "$out/bin/nbfc-gtk"
      patchShebangs "$out/bin/nbfc-gtk"
      runHook postInstall
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix GI_TYPELIB_PATH : ${lib.escapeShellArg gtkTypelibPath}
        --prefix PATH : ${
          lib.makeBinPath [
            nbfcLinux
            pkgs.systemd
            pkgs.xdg-utils
          ]
        }
      )
    '';

    meta = {
      description = "GTK fan-control GUI for NBFC-Linux";
      homepage = "https://github.com/nbfc-linux/nbfc-gtk";
      license = lib.licenses.gpl3Only;
      mainProgram = "nbfc-gtk";
      platforms = lib.platforms.linux;
    };
  };

  nbfcGtkDesktop = pkgs.makeDesktopItem {
    name = "nbfc-gtk-fan-control";
    desktopName = "NBFC Fan Control";
    genericName = "Laptop fan control";
    comment = "Control the Colorful XS laptop fans through NBFC";
    exec = "nbfc-gtk --fans";
    icon = "utilities-system-monitor";
    categories = [
      "System"
      "Settings"
    ];
  };

  nbfcConfig = {
    NotebookModel = "Colorful X15 AT 22";
    Author = "sek1ro; NixOS declarative two-fan 8-bit PWM profile with max-sensor ramp";
    EcPollInterval = 100;
    ReadWriteWords = false;
    CriticalTemperature = 72;
    CriticalTemperatureOffset = 5;
    FanConfigurations = [
      {
        ReadRegister = 207;
        WriteRegister = 231;
        Sensors = [ "@CPU" ];
        TemperatureAlgorithmType = "Max";
        MinSpeedValue = 20;
        MaxSpeedValue = 255;
        IndependentReadMinMaxValues = false;
        MinSpeedValueRead = 0;
        MaxSpeedValueRead = 0;
        ResetRequired = false;
        FanSpeedResetValue = 50;
        FanDisplayName = "CPU Fan";
        TemperatureThresholds = [
          {
            UpThreshold = 20;
            DownThreshold = 0;
            FanSpeed = 0.0;
          }
          {
            UpThreshold = 40;
            DownThreshold = 20;
            FanSpeed = 30.0;
          }
          {
            UpThreshold = 52;
            DownThreshold = 38;
            FanSpeed = 50.0;
          }
          {
            UpThreshold = 58;
            DownThreshold = 46;
            FanSpeed = 70.0;
          }
          {
            UpThreshold = 64;
            DownThreshold = 52;
            FanSpeed = 90.0;
          }
          {
            UpThreshold = 70;
            DownThreshold = 58;
            FanSpeed = 100.0;
          }
        ];
        FanSpeedPercentageOverrides = [
          {
            FanSpeedPercentage = 100.0;
            FanSpeedValue = 255;
            TargetOperation = "ReadWrite";
          }
        ];
      }
      {
        ReadRegister = 208;
        WriteRegister = 232;
        Sensors = [ "@CPU" ];
        TemperatureAlgorithmType = "Max";
        MinSpeedValue = 20;
        MaxSpeedValue = 255;
        IndependentReadMinMaxValues = false;
        MinSpeedValueRead = 0;
        MaxSpeedValueRead = 0;
        ResetRequired = false;
        FanSpeedResetValue = 50;
        FanDisplayName = "GPU Fan";
        TemperatureThresholds = [
          {
            UpThreshold = 20;
            DownThreshold = 0;
            FanSpeed = 0.0;
          }
          {
            UpThreshold = 40;
            DownThreshold = 20;
            FanSpeed = 30.0;
          }
          {
            UpThreshold = 52;
            DownThreshold = 38;
            FanSpeed = 50.0;
          }
          {
            UpThreshold = 58;
            DownThreshold = 46;
            FanSpeed = 70.0;
          }
          {
            UpThreshold = 64;
            DownThreshold = 52;
            FanSpeed = 90.0;
          }
          {
            UpThreshold = 70;
            DownThreshold = 58;
            FanSpeed = 100.0;
          }
        ];
        FanSpeedPercentageOverrides = [
          {
            FanSpeedPercentage = 100.0;
            FanSpeedValue = 255;
            TargetOperation = "ReadWrite";
          }
        ];
      }
    ];
    RegisterWriteConfigurations = [
      {
        WriteMode = "Set";
        WriteOccasion = "OnInitialization";
        Register = 44;
        Value = 8;
        ResetRequired = true;
        ResetValue = 5;
        ResetWriteMode = "Set";
        Description = "Enable manual EC fan override";
      }
    ];
  };

  serviceConfig = {
    SelectedConfigId = modelConfigPath;
    EmbeddedControllerType = "ec_sys";
  };

  nbfcVerify = pkgs.writeShellScriptBin "nbfc-colorful-verify" ''
    set -euo pipefail

    config_file=/etc/nbfc/nbfc.json
    model_file=${lib.escapeShellArg modelConfigPath}

    echo "NBFC Colorful XS verification"
    echo "service config: $config_file"
    echo "model config:   $model_file"
    echo

    selected="$(${pkgs.jq}/bin/jq -r '.SelectedConfigId' "$config_file")"
    ec_type="$(${pkgs.jq}/bin/jq -r '.EmbeddedControllerType // "auto"' "$config_file")"
    fan_count="$(${pkgs.jq}/bin/jq '.FanConfigurations | length' "$model_file")"
    max_values="$(${pkgs.jq}/bin/jq -r '[.FanConfigurations[].MaxSpeedValue] | join(",")' "$model_file")"
    writes="$(${pkgs.jq}/bin/jq -r '[.FanConfigurations[].WriteRegister] | join(",")' "$model_file")"
    reads="$(${pkgs.jq}/bin/jq -r '[.FanConfigurations[].ReadRegister] | join(",")' "$model_file")"
    algorithms="$(${pkgs.jq}/bin/jq -r '[.FanConfigurations[].TemperatureAlgorithmType] | join(",")' "$model_file")"
    sensors="$(${pkgs.jq}/bin/jq -r '[.FanConfigurations[].Sensors | join("+")] | join(",")' "$model_file")"

    test "$selected" = "$model_file"
    test "$ec_type" = "ec_sys"
    test "$fan_count" = "2"
    test "$max_values" = "255,255"
    test "$writes" = "231,232"
    test "$reads" = "207,208"
    test "$algorithms" = "Max,Max"
    test "$sensors" = "@CPU,@CPU"

    echo "OK: selected config is absolute"
    echo "OK: EC backend is ec_sys"
    echo "OK: fan count is 2"
    echo "OK: MaxSpeedValue is 255 for both fans"
    echo "OK: CPU/GPU write registers are 231/232"
    echo "OK: CPU/GPU read registers are 207/208"
    echo "OK: temperature algorithm is Max over CPU sensors for both fans"
    echo "OK: @GPU is not referenced because this laptop exposes no NBFC GPU hwmon sensor"
    echo "NOTE: GPU current-speed readback can report a negative/low value on this EC."
    echo "      Use Target Fan Speed plus audible airflow for manual GPU fan tests."
    echo

    if ${pkgs.systemd}/bin/systemctl is-active --quiet nbfc; then
      echo "Live NBFC status:"
      ${nbfcLinux}/bin/nbfc status
    else
      echo "NBFC service is not active yet. Rebuild/switch, then run: systemctl status nbfc"
    fi
  '';

  thermalStatus = pkgs.writeShellScriptBin "thermal-status" ''
    set -euo pipefail

    echo "System thermal status"
    echo "====================="

    if command -v sensors >/dev/null 2>&1; then
      echo
      echo "CPU temperature:"
      sensors | grep -E "(Core|Package|Tctl)" | head -8 || true
    fi

    echo
    echo "Thermal services:"
    ${pkgs.systemd}/bin/systemctl is-active thermald >/dev/null 2>&1 && echo "thermald: active" || echo "thermald: inactive"
    ${pkgs.systemd}/bin/systemctl is-active tuned >/dev/null 2>&1 && echo "tuned: active" || echo "tuned: inactive"
    ${pkgs.systemd}/bin/systemctl is-active tlp >/dev/null 2>&1 && echo "tlp: active (unexpected)" || echo "tlp: inactive"

    echo
    echo "NBFC:"
    if ${pkgs.systemd}/bin/systemctl is-active --quiet nbfc; then
      ${nbfcLinux}/bin/nbfc status
    else
      echo "nbfc: inactive"
    fi
  '';

  thermalMonitor = pkgs.writeShellScriptBin "thermal-monitor" ''
    set -euo pipefail

    while true; do
      clear
      date
      thermal-status
      sleep 2
    done
  '';

  asuraThermalGuard = pkgs.writeShellScriptBin "asura-thermal-guard" ''
    set -euo pipefail

    hot_c="''${ASURA_THERMAL_GUARD_HOT:-88}"
    cool_c="''${ASURA_THERMAL_GUARD_COOL:-72}"
    interval="''${ASURA_THERMAL_GUARD_INTERVAL:-2}"
    manual=0

    max_coretemp() {
      max=0
      for hwmon in /sys/class/hwmon/hwmon*; do
        [ -r "$hwmon/name" ] || continue
        [ "$(${pkgs.coreutils}/bin/cat "$hwmon/name")" = "coretemp" ] || continue
        for input in "$hwmon"/temp*_input; do
          [ -r "$input" ] || continue
          value="$(${pkgs.coreutils}/bin/cat "$input" 2>/dev/null || echo 0)"
          value_c=$((value / 1000))
          [ "$value_c" -gt "$max" ] && max="$value_c"
        done
      done
      echo "$max"
    }

    while true; do
      if ! ${pkgs.systemd}/bin/systemctl is-active --quiet nbfc; then
        ${pkgs.coreutils}/bin/sleep "$interval"
        continue
      fi

      temp="$(max_coretemp)"

      if [ "$temp" -ge "$hot_c" ] && [ "$manual" -eq 0 ]; then
        ${nbfcLinux}/bin/nbfc set --speed 100 || ${pkgs.systemd}/bin/systemctl restart nbfc || true
        ${pkgs.systemd}/bin/systemd-cat -t asura-thermal-guard -p warning \
          echo "coretemp max ''${temp}C >= ''${hot_c}C; forced NBFC fans to 100%"
        manual=1
      elif [ "$temp" -le "$cool_c" ] && [ "$manual" -eq 1 ]; then
        ${nbfcLinux}/bin/nbfc set --auto || true
        ${pkgs.systemd}/bin/systemd-cat -t asura-thermal-guard -p info \
          echo "coretemp max ''${temp}C <= ''${cool_c}C; returned NBFC to auto"
        manual=0
      fi

      ${pkgs.coreutils}/bin/sleep "$interval"
    done
  '';
in
{
  environment.systemPackages = [
    asuraThermalGuard
    nbfcLinux
    nbfcGtk
    nbfcGtkDesktop
    nbfcVerify
    thermalMonitor
    thermalStatus
  ];

  environment.etc = {
    "nbfc/nbfc.json".text = builtins.toJSON serviceConfig;
    "nbfc/Colorful X15 AT 22.json".text = builtins.toJSON nbfcConfig;
  };

  boot.kernelModules = [ "ec_sys" ];
  boot.extraModprobeConfig = ''
    options ec_sys write_support=1
  '';

  systemd.services.nbfc = {
    description = "NoteBook FanControl service";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      nbfcLinux
      pkgs.coreutils
      pkgs.jq
      pkgs.kmod
      pkgs.procps
      pkgs.systemd
      pkgs.util-linux
    ];
    preStart = ''
      modprobe ec_sys write_support=1 || true

      if ! mountpoint -q /sys/kernel/debug; then
        mount -t debugfs debugfs /sys/kernel/debug || true
      fi

      if [ -f /var/lib/nbfc/state.json ]; then
        if ! jq -e '.TargetFanSpeeds | length == 2' /var/lib/nbfc/state.json >/dev/null 2>&1; then
          rm -f /var/lib/nbfc/state.json
        fi
      fi
    '';
    serviceConfig = {
      Type = "simple";
      ExecStart = "${nbfcLinux}/bin/nbfc_service --config-file /etc/nbfc/nbfc.json";
      Restart = "on-failure";
      RestartSec = 3;
      StateDirectory = "nbfc";
    };
  };

  systemd.services.asura-thermal-guard = {
    description = "Asura XS15 emergency NBFC fan guard";
    after = [
      "nbfc.service"
      "multi-user.target"
    ];
    requires = [ "nbfc.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      config.hardware.nvidia.package
      nbfcLinux
      pkgs.coreutils
      pkgs.systemd
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${asuraThermalGuard}/bin/asura-thermal-guard";
      Restart = "always";
      RestartSec = 3;
    };
  };
}
