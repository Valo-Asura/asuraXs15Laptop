# Power management helper commands.
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "power-status" ''
      set -euo pipefail

      echo "System power status"
      echo "==================="

      if command -v acpi >/dev/null 2>&1; then
        echo
        echo "Battery:"
        acpi -b || true
      fi

      echo
      echo "CPU:"
      if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        echo "governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo unknown)"
        echo "current:  $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo unknown) kHz"
        echo "min:      $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null || echo unknown) kHz"
        echo "max:      $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo unknown) kHz"
      else
        echo "cpufreq data unavailable"
      fi

      echo
      echo "Services:"
      systemctl is-active tuned >/dev/null 2>&1 && echo "tuned: active" || echo "tuned: inactive"
      systemctl is-active thermald >/dev/null 2>&1 && echo "thermald: active" || echo "thermald: inactive"
      systemctl is-active tlp >/dev/null 2>&1 && echo "tlp: active (unexpected)" || echo "tlp: inactive"

      echo
      echo "Conflicts:"
      systemctl is-active auto-cpufreq >/dev/null 2>&1 && echo "auto-cpufreq: active (conflict)" || echo "auto-cpufreq: inactive"
      systemctl is-active power-profiles-daemon >/dev/null 2>&1 && echo "power-profiles-daemon: active (conflict)" || echo "power-profiles-daemon: inactive"

      if command -v tuned-adm >/dev/null 2>&1; then
        echo
        echo "Tuned profile:"
        tuned-adm active || true
      fi
    '')

    (pkgs.writeShellScriptBin "power-optimize" ''
      set -euo pipefail

      if command -v tuned-adm >/dev/null 2>&1; then
        if acpi -a 2>/dev/null | grep -q "off-line"; then
          sudo tuned-adm profile balanced-battery \
            || sudo tuned-adm profile powersave \
            || sudo tuned-adm profile asura-xs15-balanced \
            || true
        else
          sudo tuned-adm profile asura-xs15-balanced \
            || sudo tuned-adm profile balanced \
            || true
        fi
      fi

      power-status
    '')
  ];
}
