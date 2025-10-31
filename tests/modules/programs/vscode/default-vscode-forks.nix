{ lib, pkgs, ... }@inputs:
let
  # packageName: package
  #
  supportedForks = {
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vscode/vscode.nix
    #
    vscode = {
      pname = "vscode";
      executableName = "code";
      longName = "Code";
    };

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vscode/vscode.nix
    #
    vscode-insiders = {
      pname = "vscode-insiders";
      executableName = "code-insiders";
      longName = "Code - Insiders";
    };

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/op/openvscode-server/package.nix
    #
    openvscode-server = {
      pname = "openvscode-server";
      executableName = "openvscode-server";
      longName = "OpenVSCode Server";
      dataFolderName = ".vscode-server";
    };

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vscode/vscodium.nix
    #
    vscodium = {
      pname = "vscodium";
      executableName = "codium";
      longName = "VSCodium";
      dataFolderName = ".vscode-oss";
    };

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
      pname = "another-unknown-fork";
      executableName = "unknown-code";
      longName = "Unknown Fork";
      dataFolderName = ".unknown-fork";
    };
  };

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

              # !! this is a hack to make the test module work for unknown forks
              #
              # "programs.unknown-fork" is not a supported moduleName so we fallback to the
              # "vscode" module config for unknown forks with a custom package.
              #
              moduleName = (if packageName == "unknown-fork" then "vscode" else package.pname);

              hasDataFolderName =
                supportedForks.${packageName} ? dataFolderName
                && supportedForks.${packageName}.dataFolderName != null;

              dataFolderName = if hasDataFolderName then supportedForks.${packageName}.dataFolderName else null;
            in
            lib.nameValuePair testKey (
              testModule (
                inputs
                // {
                  forkInputs =
                    forkConfig
                    # // lib.optionalAttrs hasDataFolderName { dataFolderName = dataFolderName; }
                    // {
                      enable = true;

                      inherit
                        dataFolderName
                        moduleName
                        packageName
                        package
                        ;
                    };
                }
              )
            )

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

  # mutableExtensionsDir defaults to `true` when a single profile is set,
  # then we set it to false to test multiple profiles
  #
  (buildTestSuiteFor "multi-profile-support-with-default-profile-only" extensionsTests
    multiProfilePackages
    {
      mutableExtensionsDir = false;
    }
  )
]
