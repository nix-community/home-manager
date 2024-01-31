# NixOS module {#sec-flakes-nixos-module}

To use Home Manager as a NixOS module, a bare-minimum `flake.nix` would
be as follows:

``` nix
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jdoe = import ./home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };
  };
}
```

The Home Manager configuration is then part of the NixOS configuration
and is automatically rebuilt with the system when using the appropriate
command for the system, such as
`nixos-rebuild switch --flake <flake-uri>`.

You can use the above `flake.nix` as a template in `/etc/nixos` by

``` shell
$ nix flake new /etc/nixos -t github:nix-community/home-manager#nixos
```
