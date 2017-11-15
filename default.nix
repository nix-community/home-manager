{ pkgs ? import <nixpkgs> {} }:

import ./home-manager {
  inherit pkgs;
  path = toString ./.;
}
