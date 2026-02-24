{
  description = "Home Manager for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    {
      nixosModules = rec {
        home-manager = ./nixos;
        default = home-manager;
      };

      darwinModules = rec {
        home-manager = ./nix-darwin;
        default = home-manager;
      };

      flakeModules = rec {
        home-manager = ./flake-module.nix;
        default = home-manager;
      };

      templates = {
        default = self.templates.standalone;
        nixos = {
          path = ./templates/nixos;
          description = "Home Manager as a NixOS module,";
        };
        nix-darwin = {
          path = ./templates/nix-darwin;
          description = "Home Manager as a nix-darwin module,";
        };
        standalone = {
          path = ./templates/standalone;
          description = "Standalone setup";
        };
      };

      lib = import ./lib { inherit (nixpkgs) lib; };
    }
    // (
      let
        forAllPkgs =
          f:
          nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: f nixpkgs.legacyPackages.${system});

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
            tests = import ./tests {
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
              tests = import ./tests/integration { inherit pkgs lib; };
              renameTestPkg = n: v: lib.nameValuePair "integration-${n}" v;
            in
            lib.mapAttrs' renameTestPkg (lib.removeAttrs tests [ "all" ])
          );

        buildTests =
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            tests = import ./tests { inherit pkgs; };
            renameTestPkg = n: nixpkgs.lib.nameValuePair "test-${n}";
          in
          nixpkgs.lib.mapAttrs' renameTestPkg tests.build;

        buildTestsNoBig =
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            tests = import ./tests {
              inherit pkgs;
              enableBig = false;
            };
          in
          {
            test-all-enableBig-false-enableLegacyIfd-false = tests.build.all;
          };

        buildTestsNoBigIfd =
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            tests = import ./tests {
              inherit pkgs;
              enableBig = false;
              enableLegacyIfd = true;
            };
          in
          {
            test-all-enableBig-false-enableLegacyIfd-true = tests.build.all;
          };

        integrationTestPackages =
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            inherit (pkgs) lib;
            tests = import ./tests/integration { inherit pkgs lib; };
            renameTestPkg = n: lib.nameValuePair "integration-test-${n}";
          in
          lib.mapAttrs' renameTestPkg tests;
      in
      {
        formatter = forAllPkgs (
          pkgs:
          pkgs.treefmt.withConfig {
            runtimeInputs = with pkgs; [
              nixfmt
              deadnix
              keep-sorted
              nixf-diagnose
            ];
            settings = pkgs.lib.importTOML ./treefmt.toml;
          }
        );

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

        packages = forAllPkgs (
          pkgs:
          let
            releaseInfo = nixpkgs.lib.importJSON ./release.json;
            docs = import ./docs {
              inherit pkgs;
              inherit (releaseInfo) release isReleaseBranch;
            };
            hmPkg = pkgs.callPackage ./home-manager { path = "${self}"; };
          in
          {
            default = hmPkg;
            home-manager = hmPkg;

            create-news-entry = pkgs.writeShellScriptBin "create-news-entry" ''
              ./modules/misc/news/create-news-entry.sh
            '';

            tests = pkgs.callPackage ./tests/package.nix { flake = self; };

            docs-html = docs.manual.html;
            docs-htmlOpenTool = docs.manual.htmlOpenTool;
            docs-json = docs.options.json;
            docs-jsonModuleMaintainers = docs.jsonModuleMaintainers;
            docs-manpages = docs.manPages;
          }
        );

        legacyPackages = forAllPkgs (
          pkgs:
          let
            system = pkgs.stdenv.hostPlatform.system;
          in
          (buildTests system)
          // (integrationTestPackages system)
          // (buildTestsNoBig system)
          // (buildTestsNoBigIfd system)
          // (testChunks system)
          // (integrationTests system)
        );
      }
    );
}
