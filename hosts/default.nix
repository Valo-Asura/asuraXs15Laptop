# Host configurations
{ inputs, system, ... }:

{
  # Colorful XS 22 / X15 XS laptop.
  asura-xs15 = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs system;
      hostname = "asura-xs15";
      username = "asura";
    };
    modules = [
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.stylix.nixosModules.stylix
      inputs.nixos-hardware.nixosModules.common-pc
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.sops-nix.nixosModules.sops
      ../system
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          extraSpecialArgs = { inherit inputs system; };
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.asura = import ../home;
        };
      }
    ];
  };

  # Backward-compatible alias for old shell shortcuts while the machine moves
  # to the explicit laptop hostname.
  nixos = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs system;
      hostname = "asura-xs15";
      username = "asura";
    };
    modules = [
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.stylix.nixosModules.stylix
      inputs.nixos-hardware.nixosModules.common-pc
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.sops-nix.nixosModules.sops
      ../system
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          extraSpecialArgs = { inherit inputs system; };
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.asura = import ../home;
        };
      }
    ];
  };
}
