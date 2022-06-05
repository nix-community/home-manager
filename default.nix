{ pkgs ? import <nixpkgs> { } }:

let

  flake = (import
    (let lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    in fetchTarball {
      url =
        "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
      sha256 = lock.nodes.flake-compat.locked.narHash;
    }) { src = ./.; }).defaultNix;

in rec {
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

  inherit (flake) inputs;
}
