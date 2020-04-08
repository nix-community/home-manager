{
  edition = 201909;

  description = "Home Manager for Nix";

  outputs = { self, nixpkgs }: rec {

    nixosModules.home-manager = import ./nixos nixpkgs;

    lib = {
      homeManagerConfiguration = {
        configuration, system, homeDirectory, username,
        pkgs ? builtins.getAttr system nixpkgs.outputs.legacyPackages,
        check ? true
      }@args: import ./modules nixpkgs {
        pkgs = builtins.getAttr system nixpkgs.outputs.legacyPackages;
        configuration = { ... }: {
          imports = [configuration];
          home = {
            inherit homeDirectory username;
          };
        };
        inherit check;
      };
    };
  };
}
