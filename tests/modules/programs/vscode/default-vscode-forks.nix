{ lib, pkgs, ... }:
let
  # unknownPackage = pkgs.writeTextFile rec {
  #   name = "${derivationArgs.pname}-${derivationArgs.version}";
  #   destination = "/lib/vscode/resources/app/product.json";

  #   passthru.longName = "Unknown Fork";

  #   derivationArgs = {
  #     version = "0.1.0";

  #     pname = "unknown-fork";
  #     executableName = "unknown";
  #     longName = passthru.longName;
  #     meta.mainProgram = "unknown";
  #   };

  #   text = builtins.toJSON {
  #     dataFolderName = ".unknown";
  #     nameShort = passthru.longName;
  #   };
  # };

  # Creates a mock VSCode fork package with specified version
  #
  mkPackageWithVersion =
    packageName: version:
    pkgs.writeScriptBin "${packageName}-${version}" ""
    // {
      inherit version;
      inherit (supportedForks.${packageName})
        executableName
        longName
        pname
        ;
    };

  # packageName: package
  #
  supportedForks = {
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/co/code-cursor/package.nix
    #
    # cursor has a different package name than the actual pname
    #
    code-cursor = {
      pname = "cursor";
      executableName = "cursor";
      longName = "Cursor";
    };

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ki/kiro/package.nix
    kiro = {
      pname = "kiro";
      executableName = "kiro";
      longName = "Kiro";
    };

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/wi/windsurf/package.nix
    windsurf = {
      pname = "windsurf";
      executableName = "windsurf";
      longName = "Windsurf";
    };

    # unknown fork is a mock package for testing unknown forks
    unknown-fork = {
      pname = "vscode-unknown-fork";
      executableName = "unknown-code";
      longName = "Unknown Fork";
    };
  };

  buildTestSuiteFor =
    groupName: tests: packages: forkConfig:
    lib.foldl' (acc: pkgTests: acc // pkgTests) { } (
      lib.attrValues (
        lib.mapAttrs (
          packageName: package:
          lib.mapAttrs' (
            testName: testModule:
            let
              testKey = "vscode-forks-${package.pname}-${groupName}-${testName}";

              testConfig = {
                inherit lib pkgs;

                forkInputs = forkConfig // {
                  inherit package packageName;

                  enable = true;
                  moduleName = package.pname;
                };
              };
            in
            lib.nameValuePair testKey (testModule testConfig)

          ) tests

        ) packages
      )
    );

  singleProfilePackages = lib.mapAttrs (
    packageName: package: mkPackageWithVersion packageName "1.73.0"
  ) supportedForks;

  multiProfilePackages = lib.mapAttrs (
    packageName: package: mkPackageWithVersion packageName "1.74.0"
  ) supportedForks;

  testModules = {
    extensions = import ./profiles/extensions.nix;
    profiles-empty = import ./profiles/profiles-empty.nix;
    profiles-full = import ./profiles/profiles-full.nix;
    profiles-keybindings = import ./profiles/keybindings.nix;
    profiles-mcp = import ./profiles/mcp.nix;
    profiles-settings = import ./profiles/settings.nix;
    profiles-tasks = import ./profiles/tasks.nix;
    snippets = import ./profiles/snippets.nix;
    update-checks-file-path = import ./profiles/update-checks-file-path.nix;
    update-checks-object = import ./profiles/update-checks-object.nix;
  };

  extensionsTests = lib.filterAttrs (n: v: lib.hasPrefix "extensions" n) testModules;
in
lib.foldl' (acc: tests: acc // tests) { } [
  (buildTestSuiteFor "single-profile-support-with-defaults" testModules singleProfilePackages { })
  (buildTestSuiteFor "multi-profile-support-with-defaults" testModules multiProfilePackages { })

  (buildTestSuiteFor "multi-profile-support-with-mutable-profiles" testModules multiProfilePackages {
    mutableProfile = true;
  })

  (buildTestSuiteFor "multi-profile-support-with-immutable-profiles" testModules multiProfilePackages
    {
      mutableProfile = false;
    }
  )

  (buildTestSuiteFor "single-profile-support-with-mutable-extensions-dir" extensionsTests
    singleProfilePackages
    {
      mutableExtensionsDir = true;
    }
  )

  (buildTestSuiteFor "single-profile-support-with-immutable-extensions-dir" extensionsTests
    singleProfilePackages
    {
      mutableExtensionsDir = false;
    }
  )

  # # mutableExtensionsDir defaults to `true` when a single profile is set,
  # # then we set it to false to test multiple profiles
  # #
  (buildTestSuiteFor "multi-profile-support-with-default-profile-only" extensionsTests
    multiProfilePackages
    {
      mutableExtensionsDir = false;
    }
  )
]
