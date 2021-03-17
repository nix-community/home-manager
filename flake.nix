{
  description = "Home Manager for Nix";

  outputs = { self, nixpkgs }: rec {
    nixosModules.home-manager = import ./nixos;
    nixosModule = self.nixosModules.home-manager;

    darwinModules.home-manager = import ./nix-darwin;
    darwinModule = self.darwinModules.home-manager;

    lib = {
      hm = import ./modules/lib { lib = nixpkgs.lib; };
      homeManagerConfiguration = { configuration, system, homeDirectory
        , username, extraSpecialArgs ? { }
        , pkgs ? builtins.getAttr system nixpkgs.outputs.legacyPackages
        , check ? true }@args:
        import ./modules {
          inherit pkgs check extraSpecialArgs;
          configuration = { ... }: {
            imports = [ configuration ];
            home = { inherit homeDirectory username; };
          };
        };
    };
  };
}
