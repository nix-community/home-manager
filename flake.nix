{
  description = "Home Manager for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    {
      nixosModules = rec {
        home-manager = ./nixos;
        default = home-manager;
      };

      darwinModules = rec {
        home-manager = ./nix-darwin;
        default = home-manager;
      };

      flakeModules = rec {
        home-manager = ./flake-module.nix;
        default = home-manager;
      };

      templates = {
        default = self.templates.standalone;
        nixos = {
          path = ./templates/nixos;
          description = "Home Manager as a NixOS module,";
        };
        nix-darwin = {
          path = ./templates/nix-darwin;
          description = "Home Manager as a nix-darwin module,";
        };
        standalone = {
          path = ./templates/standalone;
          description = "Standalone setup";
        };
      };

      lib = import ./lib { inherit (nixpkgs) lib; };
    } // (let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in {
      # Include test packages as checks for primary flake.
      # Allows us to run the tests even easier.
      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;

          testPackages = let
            tests = import ./tests { inherit pkgs; };
            renameTestPkg = n: lib.nameValuePair "test-${n}";
          in lib.mapAttrs' renameTestPkg tests.build;

          integrationTestPackages = let
            tests = import ./tests/integration { inherit pkgs; };
            renameTestPkg = n: lib.nameValuePair "integration-test-${n}";
          in lib.mapAttrs' renameTestPkg tests;
        in testPackages // integrationTestPackages);

      formatter = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in pkgs.linkFarm "format" [{
          name = "bin/format";
          path = ./format;
        }]);

      # Include doc outputs in main flake.
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          releaseInfo = nixpkgs.lib.importJSON ./release.json;
          docs = import ./docs {
            inherit pkgs;
            inherit (releaseInfo) release isReleaseBranch;
          };
          hmPkg = pkgs.callPackage ./home-manager { path = "${self}"; };
        in {
          default = hmPkg;
          home-manager = hmPkg;

          docs-html = docs.manual.html;
          docs-htmlOpenTool = docs.manual.htmlOpenTool;
          docs-json = docs.options.json;
          docs-jsonModuleMaintainers = docs.jsonModuleMaintainers;
          docs-manpages = docs.manPages;
        });
    });
}
