# This is an internal Nix Flake intended for use when running tests.
#
# You can build all tests or specific tests by running
#
#   nix build --reference-lock-file flake.lock ./tests#test-all
#   nix build --reference-lock-file flake.lock ./tests#test-alacritty-empty-settings
#
# in the Home Manager project root directory.
#
# Similarly for integration tests
#
#   nix build --reference-lock-file flake.lock ./tests#integration-test-all
#   nix build --reference-lock-file flake.lock ./tests#integration-test-standalone-standard-basics

{
  description = "Tests of Home Manager for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tests = import ./. { inherit pkgs; };
        in tests.run);

      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;

          testPackages = let
            tests = import ./. { inherit pkgs; };
            renameTestPkg = n: lib.nameValuePair "test-${n}";
          in lib.mapAttrs' renameTestPkg tests.build;

          integrationTestPackages = let
            tests = import ./integration { inherit pkgs; };
            renameTestPkg = n: lib.nameValuePair "integration-test-${n}";
          in lib.mapAttrs' renameTestPkg tests;
        in testPackages // integrationTestPackages);
    };
}
