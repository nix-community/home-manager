{ pkgs }:

let
  nixosLib = import "${pkgs.path}/nixos/lib" { };

  runTest = test:
    nixosLib.runTest {
      imports = [ test { node.pkgs = pkgs; } ];
      hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
    };

  tests = {
    home-with-symbols = runTest ./standalone/home-with-symbols.nix;
    kitty = runTest ./standalone/kitty.nix;
    mu = runTest ./standalone/mu;
    nh = runTest ./standalone/nh.nix;
    nixos-basics = runTest ./nixos/basics.nix;
    rclone = runTest ./standalone/rclone;
    standalone-flake-basics = runTest ./standalone/flake-basics.nix;
    standalone-standard-basics = runTest ./standalone/standard-basics.nix;
  };
in tests // {
  all = pkgs.linkFarm "all"
    (pkgs.lib.mapAttrsToList (name: path: { inherit name path; }) tests);
}
