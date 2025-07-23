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
      forCI = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      ciTestChunks =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;

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
              targetTestsPerChunk = 50;
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
                  passthru.tests = chunkTests;
                };
            in
            lib.listToAttrs (
              lib.genList (
                i: lib.nameValuePair "test-chunk-${toString (i + 1)}" (makeChunk (i + 1) filteredTests)
              ) numChunks
            );
        in
        testChunks;

      allPackagesAndTests =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;

          renamedBuildTests =
            let
              tests = import ./. { inherit pkgs; };
              renameTestPkg = n: lib.nameValuePair "test-${n}";
            in
            lib.mapAttrs' renameTestPkg tests.build;

          integrationTestPackages =
            let
              tests = import ./integration {
                inherit pkgs;
                inherit (pkgs) lib;
              };
              renameTestPkg = n: lib.nameValuePair "integration-test-${n}";
            in
            lib.mapAttrs' renameTestPkg tests;

          # Aggregate test set without big tests
          testAllNoBig =
            let
              tests = import ./. {
                inherit pkgs;
                enableBig = false;
              };
            in
            lib.nameValuePair "test-all-no-big" tests.build.all;

          # Aggregate test set without big tests, with legacy IFD
          testAllNoBigIfd =
            let
              tests = import ./. {
                inherit pkgs;
                enableBig = false;
                enableLegacyIfd = true;
              };
            in
            lib.nameValuePair "test-all-no-big-ifd" tests.build.all;
        in
        # Merge all the packages and tests meant for the 'packages' output
        renamedBuildTests
        // integrationTestPackages
        // (lib.listToAttrs [
          testAllNoBig
          testAllNoBigIfd
        ])
        // (ciTestChunks system);

    in
    {
      # TODO: increase buildbot testing scope
      buildbot = forCI ciTestChunks;

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tests = import ./. { inherit pkgs; };
        in
        tests.run
      );

      packages = forAllSystems allPackagesAndTests;
    };
}
