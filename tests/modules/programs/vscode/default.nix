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
      longName = "Visual Studio Code";
    };

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vscode/vscode.nix
    #
    vscode-insiders = {
      pname = "vscode";
      executableName = "code-insiders";
      longName = "Visual Studio Code - Insiders";
      isInsiders = true;
    };

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/op/openvscode-server/package.nix
    #
    # openvscode-server = {
    #   pname = "openvscode-server";
    #   executableName = "openvscode-server";
    #   longName = "OpenVSCode Server";
    #   shortName = "OpenVSCode Server";
    #   dataFolderName = ".vscode-server";
    # };

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
                  forkInputs = forkConfig // {
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

  profilesTests = {
    extensions = import ./profiles/extensions.nix;
    mcp-integration = import ./mcp-integration/mcp-integration.nix;
    mcp-integration-with-override = import ./mcp-integration/mcp-integration-with-override.nix;
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

  optionsMigrationsTests = {
    v1-to-v2 = import ./options-migrations/api-v2.nix;
    v2-to-v3 = import ./options-migrations/api-v3.nix;
    v3-to-v4 = import ./options-migrations/api-v4.nix;
  };
in
lib.foldl' (acc: tests: acc // tests) { } [
  # test: options migration tests with single and multiple profiles support
  (buildTestSuiteFor "single-profile-options-migrations" optionsMigrationsTests singleProfilePackages
    {
    }
  )
  (buildTestSuiteFor "multi-profile-options-migrations" optionsMigrationsTests multiProfilePackages {
  })

  # test: all tests with package.version = "1.73.0"
  (buildTestSuiteFor "single-profile-support-with-defaults" profilesTests singleProfilePackages { })

  # test: all tests with package.version = "1.74.0"
  (buildTestSuiteFor "multi-profile-support-with-defaults" profilesTests multiProfilePackages { })

  # test: all tests with package.version = "1.74.0"
  (buildTestSuiteFor "multi-profile-support-with-mutable-profiles" profilesTests multiProfilePackages
    {
      mutableProfile = true;
    }
  )

  # test: all tests with package.version = "1.74.0"
  (buildTestSuiteFor "multi-profile-support-with-immutable-profiles" profilesTests
    multiProfilePackages
    {
      mutableProfile = false;
    }
  )

  # test: extensions tests with package.version = "1.73.0"
  (buildTestSuiteFor "single-profile-support-with-mutable-extensions-dir"
    {
      extensions = import ./profiles/extensions.nix;
    }
    singleProfilePackages
    {
      mutableExtensionsDir = true;
    }
  )

  # test: extensions tests with package.version = "1.73.0"
  (buildTestSuiteFor "single-profile-support-with-immutable-extensions-dir"
    {
      extensions = import ./profiles/extensions.nix;
    }
    singleProfilePackages
    {
      mutableExtensionsDir = false;
    }
  )

  # mutableExtensionsDir defaults to `true` when a single profile is set,
  # then we set it to false to test multiple profiles
  #
  # test: extensions tests with package.version = "1.74.0"
  (buildTestSuiteFor "multi-profile-support-with-default-profile-only"
    {
      extensions = import ./profiles/extensions.nix;
    }
    multiProfilePackages
    {
      mutableExtensionsDir = false;
    }
  )

  # test: haskell support tests for vscode only with package.version = "1.73.0"
  (buildTestSuiteFor "with-haskell-support" {
    add-settings-and-extensions = import ./vscode-haskell.nix;
  } { vscode = singleProfilePackages.vscode; } { })
]
