{
  description = "Home Manager for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
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
    }
    // (
      let
        forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

        treefmtEval = forAllSystems (
          system:
          treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
            # Formatting configuration
            programs = {
              nixfmt.enable = true;
            };
          }
        );
      in
      {
        checks = forAllSystems (system: {
          formatting = treefmtEval.${system}.config.build.check self;
        });

        formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

        packages = forAllSystems (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            releaseInfo = nixpkgs.lib.importJSON ./release.json;
            docs = import ./docs {
              inherit pkgs;
              inherit (releaseInfo) release isReleaseBranch;
            };
            hmPkg = pkgs.callPackage ./home-manager { path = "${self}"; };
          in
          {
            default = hmPkg;
            home-manager = hmPkg;

            docs-html = docs.manual.html;
            docs-htmlOpenTool = docs.manual.htmlOpenTool;
            docs-json = docs.options.json;
            docs-jsonModuleMaintainers = docs.jsonModuleMaintainers;
            docs-manpages = docs.manPages;
          }
        );
      }
    );
}
