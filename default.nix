{ pkgs ? import <nixpkgs> { } }:

let
  extendedLib = import ./modules/lib/stdlib-extended.nix pkgs.lib;
  doc = (import ./doc {
    lib = extendedLib;
    pkgs = pkgs;
  });
in rec {
  home-manager = pkgs.callPackage ./home-manager { path = toString ./.; };

  install =
    pkgs.callPackage ./home-manager/install.nix { inherit home-manager; };

  nixos = import ./nixos;

  html-manual = doc.manual.html;

  manPages = doc.manPages;

  path = ./.;
}
