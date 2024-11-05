{ pkgs }:

let
  nixosLib = import "${pkgs.path}/nixos/lib" { };

  runTest = test:
    nixosLib.runTest {
      imports = [ test { node.pkgs = pkgs; } ];
      hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
    };

  tests = {
    kitty = runTest ./standalone/kitty.nix;
    nixos-basics = runTest ./nixos/basics.nix;
    standalone-flake-basics = runTest ./standalone/flake-basics.nix;
    standalone-standard-basics = runTest ./standalone/standard-basics.nix;
  };
in tests // {
  all = pkgs.linkFarm "all"
    (pkgs.lib.mapAttrsToList (name: path: { inherit name path; }) tests);
}
