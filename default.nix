{ pkgs ? import <nixpkgs> { } }:

rec {
  docs = with import ./docs { inherit pkgs; }; {
    html = manual.html;
    manPages = manPages;
    json = options.json;
    jsonModuleMaintainers = jsonModuleMaintainers; # Unstable, mainly for CI.
  };

  home-manager = pkgs.callPackage ./home-manager { path = toString ./.; };

  install =
    pkgs.callPackage ./home-manager/install.nix { inherit home-manager; };

  nixos = import ./nixos;

  path = ./.;
}
