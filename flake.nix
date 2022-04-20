{
  description = "Home Manager for Nix";

  outputs = { self, nixpkgs }:
    let
      # List of systems supported by home-manager binary
      supportedSystems = with nixpkgs.lib.platforms; linux ++ darwin;

      # Function to generate a set based on supported systems
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in rec {
      nixosModules.home-manager = import ./nixos;
      nixosModule = self.nixosModules.home-manager;

      darwinModules.home-manager = import ./nix-darwin;
      darwinModule = self.darwinModules.home-manager;

      packages = forAllSystems (system:
        let docs = import ./docs { pkgs = nixpkgsFor.${system}; };
        in {
          home-manager = nixpkgsFor.${system}.callPackage ./home-manager { };
          docs-html = docs.manual.html;
          docs-manpages = docs.manPages;
          docs-json = docs.options.json;
          default = self.packages.${system}.home-manager;
        });

      # defaultPackage is deprecated as of Nix 2.7.0
      defaultPackage = forAllSystems (system: self.packages.${system}.default);

      apps = forAllSystems (system: {
        home-manager = {
          type = "app";
          program = "${defaultPackage.${system}}/bin/home-manager";
        };
      });

      defaultApp = forAllSystems (system: apps.${system}.home-manager);

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
    };
}
