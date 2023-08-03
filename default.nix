{ pkgs ? null }:
let
  pkgsPath = if pkgs == null then <nixpkgs> else pkgs.path;
  pkgs_ = if pkgs == null then import <nixpkgs> { } else pkgs;
in rec {
  docs = let releaseInfo = pkgs.lib.importJSON ./release.json;
  in with import ./docs {
    inherit pkgsPath;
    pkgs = pkgs_;
    inherit (releaseInfo) release isReleaseBranch;
  }; {
    html = manual.html;
    manPages = manPages;
    json = options.json;
    jsonModuleMaintainers = jsonModuleMaintainers; # Unstable, mainly for CI.
  };

  home-manager = pkgs_.callPackage ./home-manager {
    inherit pkgsPath;
    path = toString ./.;
  };

  install =
    pkgs_.callPackage ./home-manager/install.nix { inherit home-manager; };

  nixos = import ./nixos pkgsPath;

  path = ./.;
}
