{ pkgs ? import <nixpkgs> {} }:

rec {
  home-manager = import ./home-manager {
    inherit pkgs;
    path = ./.;
  };

  install =
    pkgs.runCommand
      "home-manager-install"
      { propagatedBuildInputs = [ home-manager ]; }
      "";

  nixos = import ./nixos;
}
