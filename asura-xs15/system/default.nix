# System configuration entry point.
{
  imports = [
    ./hardware-configuration.nix

    ./boot.nix
    ./kernel-cachyos.nix
    ./networking.nix
    ./users.nix
    ./locale.nix
    ./display.nix
    ./login.nix
    ./hardware.nix
    ./audio.nix
    ./services.nix
    ./mysql.nix
    ./virtual-machines.nix
    ./programs.nix
    ./gaming.nix
    ../noctaliaShell
    ./packages.nix
    ./environment.nix
    ./theming.nix
    ./browser-theming.nix
    ./maintenance.nix
    ./performance.nix
    ./desktop-performance.nix
    ./filesystems.nix
    ./windows-mount-helper.nix
    ./thermal.nix
    ./fan-control-tools.nix
    ./power-management-tools.nix
    ./vibewall.nix
  ];
}
