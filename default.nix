{ pkgs ? import <nixpkgs> { } }:

let
  path = builtins.path {
    path = ./.;
    name = "home-manager-source";
  };

in rec {
  docs = let releaseInfo = pkgs.lib.importJSON ./release.json;
  in with import ./docs {
    inherit pkgs;
    inherit (releaseInfo) release isReleaseBranch;
  }; {

    inherit manPages jsonModuleMaintainers;
    inherit (manual) html htmlOpenTool;
    inherit (options) json;
  };

  home-manager = pkgs.callPackage ./home-manager { inherit path; };

  install =
    pkgs.callPackage ./home-manager/install.nix { inherit home-manager; };

  nixos = import ./nixos;
  lib = import ./lib { inherit (pkgs) lib; };

  inherit path;
}
