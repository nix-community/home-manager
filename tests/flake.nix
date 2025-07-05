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

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tests = import ./. { inherit pkgs; };
        in
        tests.run
      );

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;

          testPackages =
            let
              tests = import ./. { inherit pkgs; };
              renameTestPkg = n: lib.nameValuePair "test-${n}";
            in
            lib.mapAttrs' renameTestPkg tests.build;

          integrationTestPackages =
            let
              tests = import ./integration { inherit pkgs; };
              renameTestPkg = n: lib.nameValuePair "integration-test-${n}";
            in
            lib.mapAttrs' renameTestPkg tests;

          testAllNoBig =
            let
              tests = import ./. {
                inherit pkgs;
                enableBig = false;
              };
            in
            lib.nameValuePair "test-all-no-big" tests.build.all;

          testAllNoBigIfd =
            let
              tests = import ./. {
                inherit pkgs;
                enableBig = false;
                enableLegacyIfd = true;
              };
            in
            lib.nameValuePair "test-all-no-big-ifd" tests.build.all;

          # Create chunked test packages for better CI parallelization
          testChunks =
            let
              tests = import ./. {
                inherit pkgs;
                # Disable big tests since this is only used for CI
                enableBig = false;
              };
              allTests = lib.attrNames tests.build;
              # Remove 'all' from the test list as it's a meta-package
              filteredTests = lib.filter (name: name != "all") allTests;
              # NOTE: Just a starting value, we can tweak this to find a good value.
              targetTestsPerChunk = 250;
              numChunks = lib.max 1 (
                builtins.ceil ((builtins.length filteredTests) / (targetTestsPerChunk * 1.0))
              );
              chunkSize = builtins.ceil ((builtins.length filteredTests) / (numChunks * 1.0));

              makeChunk =
                chunkNum: testList:
                let
                  start = (chunkNum - 1) * chunkSize;
                  end = lib.min (start + chunkSize) (builtins.length testList);
                  chunkTests = lib.sublist start (end - start) testList;
                  chunkAttrs = lib.genAttrs chunkTests (name: tests.build.${name});
                in
                pkgs.symlinkJoin {
                  name = "test-chunk-${toString chunkNum}";
                  paths = lib.attrValues chunkAttrs;
                };
            in
            lib.listToAttrs (
              lib.genList (
                i: lib.nameValuePair "test-chunk-${toString (i + 1)}" (makeChunk (i + 1) filteredTests)
              ) numChunks
            );
        in
        testPackages
        // integrationTestPackages
        // testChunks
        // (lib.listToAttrs [
          testAllNoBig
          testAllNoBigIfd
        ])
      );
    };
}
