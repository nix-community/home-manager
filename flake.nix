{
  description = "Home Manager for Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, utils }:
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

      lib = {
        hm = import ./modules/lib { lib = nixpkgs.lib; };
        homeManagerConfiguration = { configuration, system, homeDirectory
          , username, extraModules ? [ ], extraSpecialArgs ? { }
          , pkgs ? builtins.getAttr system nixpkgs.outputs.legacyPackages
          , lib ? pkgs.lib, check ? true, stateVersion ? "20.09" }@args:
          assert nixpkgs.lib.versionAtLeast stateVersion "20.09";

          import ./modules {
            inherit pkgs lib check extraSpecialArgs;
            configuration = { ... }: {
              imports = [ configuration ] ++ extraModules;
              home = { inherit homeDirectory stateVersion username; };
              nixpkgs = { inherit (pkgs) config overlays; };
            };
          };
      };
    } // utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        docs = import ./docs { inherit pkgs; };
      in {
        packages = rec {
          home-manager = pkgs.callPackage ./home-manager { };
          docs-html = docs.manual.html;
          docs-manpages = docs.manPages;
          docs-json = docs.options.json;
          default = home-manager;
        };
        # deprecated in Nix 2.7
        defaultPackage = self.packages.${system}.default;
      });
}
