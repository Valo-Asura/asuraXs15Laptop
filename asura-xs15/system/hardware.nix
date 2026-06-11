# Hardware Configuration
{
  config,
  lib,
  pkgs,
  ...
}:

let
  earlyNvidiaModules = [
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];
  hasEarlyNvidiaModule =
    modules: builtins.any (module: builtins.elem module earlyNvidiaModules) modules;
in
{
  assertions = [
    {
      assertion = !(hasEarlyNvidiaModule config.boot.initrd.kernelModules);
      message = "Asura XS15: NVIDIA modules must not be loaded from initrd; use the i915 panel path and let PRIME load NVIDIA after real root.";
    }
    {
      assertion = !(hasEarlyNvidiaModule config.boot.kernelModules);
      message = "Asura XS15: NVIDIA modules must not be loaded through systemd-modules-load; do not recreate the old CachyOS early NVIDIA boot hang.";
    }
  ];

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    i2c.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    bluetooth.enable = true;
    nvidia = {
      modesetting.enable = lib.mkForce true;
      powerManagement.enable = false;
      nvidiaPersistenced = true;
      open = lib.mkForce false;
      nvidiaSettings = true;
      # Pin the older 580 branch explicitly for stability instead of following
      # the moving production/stable aliases, which currently resolve to 595.
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      prime = {
        offload = {
          enable = lib.mkForce true;
          enableOffloadCmd = lib.mkForce true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  # Load v4l2loopback module
  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=9 card_label="OBS Virtual Camera" exclusive_caps=1
  '';
  # Keep only Intel KMS in the initrd. The previous CachyOS setup on this exact
  # hybrid laptop hung when NVIDIA was forced into early initramfs loading.
  # PRIME/offload and persistenced still configure the dGPU after real root.
  boot.initrd.kernelModules = [
    "i915"
  ];
  boot.kernelModules = [
    "v4l2loopback"
  ];

  # Empty declarative stubs win over stale imperative Arch/CachyOS-style files
  # if they ever appear under /etc/modules-load.d. This is not a blacklist:
  # the NixOS NVIDIA/PRIME stack still loads the driver after real root.
  environment.etc = {
    "modules-load.d/nvidia.conf".text = "";
    "modules-load.d/nvidia-drm.conf".text = "";
    "modules-load.d/nvidia-modeset.conf".text = "";
    "modules-load.d/nvidia-uvm.conf".text = "";
  };
}
