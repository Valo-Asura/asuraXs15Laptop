# System configuration
{
  hostname,
  inputs,
  ...
}:

{
  imports = [
    ../asura-xs15/system
  ];

  networking.hostName = hostname;

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-substitution-jobs = 64;
      http-connections = 128;
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
  };
}
