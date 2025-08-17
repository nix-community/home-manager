{ lib, pkgs }:

let
  nixosLib = import "${pkgs.path}/nixos/lib" { };

  runTest =
    test:
    nixosLib.runTest {
      imports = [
        test
        { node.pkgs = pkgs; }
      ];
      hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
    };

  tests = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    home-with-symbols = runTest ./standalone/home-with-symbols.nix;
    kitty = runTest ./standalone/kitty.nix;
    mu = runTest ./standalone/mu;
    nh = runTest ./standalone/nh.nix;
    nixos-basics = runTest ./nixos/basics.nix;
    nixos-legacy-profile-management = runTest ./nixos/legacy-profile-management.nix;
    rclone = runTest ./standalone/rclone;
    rclone-sops-nix = runTest ./standalone/rclone/sops-nix.nix;
    rclone-agenix = runTest ./standalone/rclone/agenix.nix;
    restic = runTest ./standalone/restic.nix;
    standalone-flake-basics = runTest ./standalone/flake-basics.nix;
    standalone-specialisation = runTest ./standalone/specialisation.nix;
    standalone-standard-basics = runTest ./standalone/standard-basics.nix;
  };
in
tests
// {
  all = pkgs.linkFarm "all" (pkgs.lib.mapAttrsToList (name: path: { inherit name path; }) tests);
}
