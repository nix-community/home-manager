# How do I install packages from Nixpkgs unstable? {#_how_do_i_install_packages_from_nixpkgs_unstable}

If you are using a stable version of Nixpkgs but would like to install
some particular packages from Nixpkgs unstable -- or some other channel
-- then you can import the unstable Nixpkgs and refer to its packages
within your configuration.

With channels, something like

``` nix
{ pkgs, config, ... }:

let
  pkgsUnstable = import <nixpkgs-unstable> {};
in
{
  home.packages = [
    pkgsUnstable.foo
  ];
  # …
}
```

should work provided you have a Nix channel called `nixpkgs-unstable`.

You can add the `nixpkgs-unstable` channel by running

``` shell
$ nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
$ nix-channel --update
```

With flakes, add another Nixpkgs input and pass its packages to your
Home Manager modules. For example, a standalone Home Manager flake can
define the following. Replace 25.11 with the release branch your
configuration follows.

``` nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
  };

  outputs =
    { nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      # Replace this with the system of your Home Manager configuration.
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgsUnstable = nixpkgs-unstable.legacyPackages.${system};
    in
    {
      homeConfigurations.jdoe = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit pkgsUnstable; };
        modules = [ ./home.nix ];
      };
    };
}
```

and then use the extra argument in `home.nix`:

``` nix
{ pkgsUnstable, ... }:

{
  home.packages = [
    pkgsUnstable.foo
  ];
}
```

When Home Manager is used as a NixOS or nix-darwin module, pass the
extra package set with `home-manager.extraSpecialArgs` in the system
configuration:

``` nix
outputs =
  { nixpkgs, nixpkgs-unstable, home-manager, ... }:
  let
    # Replace this with the system of your NixOS or nix-darwin configuration.
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        home-manager.nixosModules.home-manager
        ({ config, ... }: {
          home-manager.extraSpecialArgs = {
            pkgsUnstable = import nixpkgs-unstable {
              inherit system;
              config = config.nixpkgs.config;
              overlays = config.nixpkgs.overlays;
            };

            # If you use a stock Nixpkgs configuration, you can use:
            # pkgsUnstable = nixpkgs-unstable.legacyPackages.${system};
          };
        })
      ];
    };
  };
```

The nix-darwin setup is the same pattern with
`darwin.lib.darwinSystem` and
`home-manager.darwinModules.home-manager`.
