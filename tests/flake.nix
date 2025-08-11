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

      testChunks =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;

          # Create chunked test packages for better CI parallelization
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

      integrationTests =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;
        in
        lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
          let
            tests = import ./integration { inherit pkgs lib; };
            renameTestPkg = n: v: lib.nameValuePair "integration-${n}" v;
          in
          lib.mapAttrs' renameTestPkg (lib.removeAttrs tests [ "all" ])
        );

      # Test group definitions
      buildTests =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tests = import ./. { inherit pkgs; };
          renameTestPkg = n: nixpkgs.lib.nameValuePair "test-${n}";
        in
        nixpkgs.lib.mapAttrs' renameTestPkg tests.build;

      buildTestsNoBig =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tests = import ./. {
            inherit pkgs;
            enableBig = false;
          };
        in
        {
          test-all-no-big = tests.build.all;
        };

      buildTestsNoBigIfd =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tests = import ./. {
            inherit pkgs;
            enableBig = false;
            enableLegacyIfd = true;
          };
        in
        {
          test-all-no-big-ifd = tests.build.all;
        };

      integrationTestPackages =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;
          tests = import ./integration { inherit pkgs lib; };
          renameTestPkg = n: lib.nameValuePair "integration-test-${n}";
        in
        lib.mapAttrs' renameTestPkg tests;

    in
    {
      # TODO: increase buildbot testing scope
      buildbot = forCI (
        system:
        let
          allIntegrationTests = integrationTests system;
          workingIntegrationTests = nixpkgs.lib.filterAttrs (
            name: _:
            nixpkgs.lib.elem name [
              "integration-nixos-basics"
              "integration-nixos-legacy-profile-management"
            ]
          ) allIntegrationTests;
        in
        (testChunks system) // workingIntegrationTests
      );

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
        (buildTests system)
        // (integrationTestPackages system)
        // (buildTestsNoBig system)
        // (buildTestsNoBigIfd system)
        // (testChunks system)
        // (integrationTests system)
      );
    };
}
