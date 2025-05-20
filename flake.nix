{
  description = "Home Manager for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
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
        forAllPkgs =
          f:
          nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: f nixpkgs.legacyPackages.${system});
      in
      {
        formatter = forAllPkgs (
          pkgs:
          pkgs.treefmt.withConfig {
            runtimeInputs = with pkgs; [
              nixfmt-rfc-style
              keep-sorted
            ];
            settings = pkgs.lib.importTOML ./treefmt.toml;
          }
        );

        packages = forAllPkgs (
          pkgs:
          let
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

            create-news-entry = pkgs.writeShellScriptBin "create-news-entry" ''
              ./modules/misc/news/create-news-entry.sh
            '';

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
