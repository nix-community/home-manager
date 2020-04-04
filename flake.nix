{
  edition = 201909;

  description = "Home Manager for Nix";

  outputs = { self, nixpkgs }:
    {
      nixosModules.home-manager = import ./nixos;
    };
}
