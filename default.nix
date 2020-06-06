{ pkgs ? import <nixpkgs> { } }:

rec {
  docs = with import ./doc { inherit pkgs; }; {
    html = manual.html;
    manPages = manPages;
    json = options.json;
  };

  home-manager = pkgs.callPackage ./home-manager { path = toString ./.; };

  install =
    pkgs.callPackage ./home-manager/install.nix { inherit home-manager; };

  nixos = import ./nixos;

  path = ./.;
}
