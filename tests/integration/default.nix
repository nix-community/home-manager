{ pkgs }:

let
  nixosLib = import "${pkgs.path}/nixos/lib" { };

  runTest = test:
    nixosLib.runTest {
      imports = [ test { node.pkgs = pkgs; } ];
      hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
    };

  tests = {
    nixos-basics = runTest ./nixos/basics.nix;
    nixos-legacy-profile-management =
      runTest ./nixos/legacy-profile-management.nix;
    standalone-flake-basics = runTest ./standalone/flake-basics.nix;
    standalone-standard-basics = runTest ./standalone/standard-basics.nix;
  };
in tests // {
  all = pkgs.linkFarm "all"
    (pkgs.lib.mapAttrsToList (name: path: { inherit name path; }) tests);
}
