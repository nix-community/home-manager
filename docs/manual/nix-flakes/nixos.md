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
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.jdoe = ./home.nix;
          }
        ];
      };
    };
  };
}
```

Use `home-manager.extraSpecialArgs` to pass arguments from your flake to
`home.nix` and any imported Home Manager modules. For example, the
configuration above makes the complete `inputs` attrset available to modules,
so they can declare arguments such as `{ inputs, ... }:`.

The lower-level mechanism behind this is `_module.args`. Set
`_module.args.<name>` from inside a module only when you need to provide a
module argument from within the module graph itself. For values that originate
outside the module graph, such as flake inputs, prefer
`home-manager.extraSpecialArgs`.

The Home Manager configuration is then part of the NixOS configuration
and is automatically rebuilt with the system when using the appropriate
command for the system, such as
`nixos-rebuild switch --flake <flake-uri>`.

You can use the above `flake.nix` as a template in `/etc/nixos` by

``` shell
$ nix flake new /etc/nixos -t github:nix-community/home-manager#nixos
```
