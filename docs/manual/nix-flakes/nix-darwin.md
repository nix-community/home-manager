# nix-darwin module {#sec-flakes-nix-darwin-module}

The flake-based setup of the Home Manager nix-darwin module is similar
to that of NixOS. The `flake.nix` would be:

``` nix
{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, darwin, ... }: {
    darwinConfigurations = {
      hostname = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          ./configuration.nix
          home-manager.darwinModules.home-manager
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

and it is also rebuilt with the nix-darwin generations. The rebuild
command here may be `darwin-rebuild switch --flake <flake-uri>`.

You can use the above `flake.nix` as a template in `~/.config/darwin` by

``` shell
$ nix flake new ~/.config/darwin -t github:nix-community/home-manager#nix-darwin
```
