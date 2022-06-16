{
  description = "Home Manager for Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.nmd.url = "gitlab:rycee/nmd";
  inputs.nmd.flake = false;
  inputs.nmt.url = "gitlab:rycee/nmt";
  inputs.nmt.flake = false;

  inputs.utils.url = "github:numtide/flake-utils";
  inputs.flake-compat.url = "github:edolstra/flake-compat";
  inputs.flake-compat.flake = false;

  outputs = { self, nixpkgs, nmd, utils, ... }:
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
          , username, extraModules ? [ ], extraSpecialArgs ? { }, pkgs
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
        pkgs = nixpkgs.legacyPackages.${system};
        docs = import ./docs {
          inherit pkgs;
          nmdSrc = nmd;
        };
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
