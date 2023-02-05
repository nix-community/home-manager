{
  description = "Home Manager for Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, utils, ... }:
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

      lib = {
        hm = (import ./modules/lib/stdlib-extended.nix nixpkgs.lib).hm;
        homeManagerConfiguration = { modules ? [ ], pkgs, lib ? pkgs.lib
          , extraSpecialArgs ? { }, check ? true
            # Deprecated:
          , configuration ? null, extraModules ? null, stateVersion ? null
          , username ? null, homeDirectory ? null, system ? null }@args:
          let
            msgForRemovedArg = ''
              The 'homeManagerConfiguration' arguments

                - 'configuration',
                - 'username',
                - 'homeDirectory'
                - 'stateVersion',
                - 'extraModules', and
                - 'system'

              have been removed. Instead use the arguments 'pkgs' and
              'modules'. See the 22.11 release notes for more: https://nix-community.github.io/home-manager/release-notes.html#sec-release-22.11-highlights 
            '';

            throwForRemovedArgs = v:
              let
                used = builtins.filter (n: (args.${n} or null) != null) [
                  "configuration"
                  "username"
                  "homeDirectory"
                  "stateVersion"
                  "extraModules"
                  "system"
                ];
                msg = msgForRemovedArg + ''


                  Deprecated args passed: ''
                  + builtins.concatStringsSep " " used;
              in lib.throwIf (used != [ ]) msg v;

          in throwForRemovedArgs (import ./modules {
            inherit pkgs lib check extraSpecialArgs;
            configuration = { ... }: {
              imports = modules;
              nixpkgs = { inherit (pkgs) config overlays; };
            };
          });
      };
    } // utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        docs = import ./docs { inherit pkgs; };
        tests = import ./tests { inherit pkgs; };
      in {
        devShells.tests = tests.run;
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
