# flake-parts module {#sec-flakes-flake-parts-module}

When using [flake-parts](https://flake.parts) you may wish to import Home
Manager's flake module, `flakeModules.home-manager`.

```nix
{
  description = "flake-parts configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{
    flake-parts,
    home-manager,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # Import home-manager's flake module
        inputs.home-manager.flakeModules.home-manager
      ];
      flake = {
        # Reusable Home Manager module.
        homeModules.bash= { pkgs, ... }: {
          programs.bash = {
            enable = true;
            shellAliases = {
              ll = "ls -l";
            };
          };
          home.packages = [ pkgs.hello ];
        };

        # Concrete Home Manager configuration.
        homeConfigurations.alice = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          modules = [
            inputs.self.homeModules.bash
            {
              home.username = "alice";
              home.homeDirectory = "/home/alice";
              home.stateVersion = "25.11";
            }
          ];
        };
      };
      # See flake.parts for more features, such as `perSystem`
    };
}
```

The flake module defines the `flake.homeModules` and `flake.homeConfigurations`
options, allowing them to be properly merged if they are defined in multiple
modules.

If you are only defining `homeModules` and/or `homeConfigurations` once in a
single module, flake-parts should work fine without importing
`flakeModules.home-manager`.
