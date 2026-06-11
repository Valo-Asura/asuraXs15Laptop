# Thermal management. NBFC-specific fan control lives in the fan-control-tools module.
{ pkgs, lib, ... }:

{
  services.thermald.enable = true;

  # Noctalia's power UI uses tuned. Keep TLP disabled to avoid split ownership.
  services.tlp.enable = lib.mkForce false;
  services.auto-cpufreq.enable = false;
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.tuned = {
    enable = true;
    settings = {
      dynamic_tuning = true;
      sleep_interval = 1;
      update_interval = 5;
    };
    profiles = {
      asura-xs15-balanced = {
        main = {
          summary = "Asura XS15 balanced profile with cooler Alder Lake boost behavior";
          include = "balanced";
        };
        cpu = {
          governor = "schedutil|powersave";
          energy_perf_bias = "normal";
          energy_performance_preference = "balance_power";
          boost = 1;
        };
        acpi.platform_profile = "balanced";
        video.panel_power_savings = 0;
      };

      asura-xs15-performance = {
        main = {
          summary = "Asura XS15 performance profile without full server-style CPU pinning";
          include = "balanced";
        };
        cpu = {
          governor = "schedutil|powersave";
          energy_perf_bias = "normal";
          energy_performance_preference = "balance_performance";
          boost = 1;
        };
        acpi.platform_profile = "performance|balanced";
        video.panel_power_savings = 0;
      };

      asura-xs15-balanced-battery = {
        main = {
          summary = "Asura XS15 battery-balanced profile with cooler boost behavior";
          include = "balanced-battery";
        };
        cpu = {
          governor = "schedutil|powersave";
          energy_perf_bias = "powersave";
          energy_performance_preference = "balance_power";
          boost = 0;
        };
        acpi.platform_profile = "low-power|balanced";
        video.panel_power_savings = 1;
      };
    };
    ppdSettings = {
      main.default = "balanced";
      profiles = {
        balanced = "asura-xs15-balanced";
        performance = "asura-xs15-performance";
        power-saver = "balanced-battery";
      };
      battery.balanced = "asura-xs15-balanced-battery";
    };
    recommend.asura-xs15-balanced = { };
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
    acpi
    powertop
  ];

  boot.kernelModules = [
    "coretemp"
  ];

  boot.kernelParams = [
    "acpi_enforce_resources=lax"
  ];
}
