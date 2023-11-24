{ pkgs ? null }@args:

let

  pkgs = (import ./modules/pkgs).extendAttrOrDefault args;

in rec {
  docs = let releaseInfo = pkgs.lib.importJSON ./release.json;
  in with import ./docs {
    inherit pkgs;
    inherit (releaseInfo) release isReleaseBranch;
  }; {
    html = manual.html;
    manPages = manPages;
    json = options.json;
    jsonModuleMaintainers = jsonModuleMaintainers; # Unstable, mainly for CI.
  };

  home-manager = pkgs.callPackage ./home-manager { path = toString ./.; };

  install =
    pkgs.callPackage ./home-manager/install.nix { inherit home-manager; };

  nixos = import ./nixos;

  nix-darwin = import ./nix-darwin;

  path = ./.;
}
