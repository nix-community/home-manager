{
  description = "Manage a user environment using Nix";
  edition = 201909;
  inputs.nixpkgs.url = "github:edolstra/nixpkgs/release-19.09";
  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {

      nixosModules.home-manager = import ./nixos;

      checks = forAllSystems (system: {
        nixos =
          # Evaluate the NixOS module and build the home-manager package.
          let
            nixosSystem = nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [ self.nixosModules.home-manager ];
            };
          in nixosSystem.pkgs.home-manager;
      });

    };
}
