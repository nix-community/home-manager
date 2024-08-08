{
  description = "Home Manager for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    {
      nixosModules = rec {
        home-manager = import ./nixos;
        default = home-manager;
      };
      # deprecated in Nix 2.8
      nixosModule = self.nixosModules.default;

      darwinModules = rec {
        home-manager = import ./nix-darwin;
        default = home-manager;
      };
      # unofficial; deprecated in Nix 2.8
      darwinModule = self.darwinModules.default;

      templates = {
        standalone = {
          path = ./templates/standalone;
          description = "Standalone setup";
        };
        nixos = {
          path = ./templates/nixos;
          description = "Home Manager as a NixOS module,";
        };
        nix-darwin = {
          path = ./templates/nix-darwin;
          description = "Home Manager as a nix-darwin module,";
        };
      };

      defaultTemplate = self.templates.standalone;

      lib = import ./lib { inherit (nixpkgs) lib; };
    } // (let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tests = import ./tests { inherit pkgs; };
        in tests.run);

      formatter = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in pkgs.linkFarm "format" [{
          name = "bin/format";
          path = ./format;
        }]);

      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;
          releaseInfo = nixpkgs.lib.importJSON ./release.json;
          docs = import ./docs {
            inherit pkgs;
            inherit (releaseInfo) release isReleaseBranch;
          };
          hmPkg = pkgs.callPackage ./home-manager { path = "${./.}"; };

          testPackages = let
            tests = import ./tests { inherit pkgs; };
            renameTestPkg = n: lib.nameValuePair "test-${n}";
          in lib.mapAttrs' renameTestPkg tests.build;

          integrationTestPackages = let
            tests = import ./tests/integration { inherit pkgs; };
            renameTestPkg = n: lib.nameValuePair "integration-test-${n}";
          in lib.mapAttrs' renameTestPkg tests;
        in {
          default = hmPkg;
          home-manager = hmPkg;

          docs-html = docs.manual.html;
          docs-json = docs.options.json;
          docs-manpages = docs.manPages;
        } // testPackages // integrationTestPackages);

      defaultPackage = forAllSystems (system: self.packages.${system}.default);
    });
}
