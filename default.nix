{ pkgs ? import <nixpkgs> {} }:

rec {
  home-manager = import ./home-manager {
    inherit pkgs;
    path = toString ./.;
  };

  install = import ./home-manager/install.nix {
    inherit home-manager pkgs;
  };

  nixos = import ./nixos;

  tests = import ./tests {
    inherit pkgs;
  };
}
