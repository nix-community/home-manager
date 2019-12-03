{
  edition = 201909;

  description = "Home Manager for Nix";

  outputs = { self, nixpkgs }: rec {

    nixosModules.home-manager = import ./nixos nixpkgs;

  };
}
