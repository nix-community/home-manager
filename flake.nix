{
  edition = 201909;

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      lib.mkHome = configuration:
        import home-manager/home-manager.nix {
          inherit pkgs;
          configuration = configuration // { _module.args.pkgs = pkgs; };
          nixpkgsSrc = nixpkgs;
        };

      packages.${system}.home-manager = pkgs.callPackage ./home-manager { };

      defaultPackage.${system} = self.packages.${system}.home-manager;

      homeConfiguration = self.lib.mkHome {
        home.homeDirectory = "/home/username";
        home.username = "username";
      };
    };
}
