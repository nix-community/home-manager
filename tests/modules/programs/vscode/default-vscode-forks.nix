{ lib, pkgs, ... }:
let
  # unknownPackage = pkgs.writeTextFile rec {
  #   name = "${derivationArgs.pname}-${derivationArgs.version}";
  #   derivationArgs = {
  #     pname = "test-vscode-unknown";
  #     version = "0.1.0";
  #   };
  #   text = builtins.toJSON {
  #     dataFolderName = ".test-vscode-unknown";
  #     nameShort = passthru.longName;
  #   };
  #   destination = "/lib/vscode/resources/app/product.json";
  #   passthru.longName = "Test VSCode Fork";
  # };
  testModules = {
    empty-profiles = import ./profiles/profiles-empty.nix;
    extensions = import ./profiles/extensions.nix;
    full-profiles = import ./profiles/profiles-full.nix;
    keybindings = import ./profiles/keybindings.nix;
    mcp = import ./profiles/mcp.nix;
    settings = import ./profiles/settings.nix;
    snippets = import ./profiles/snippets.nix;
    tasks = import ./profiles/tasks.nix;
    update-checks-file-path = import ./profiles/update-checks-file-path.nix;
    update-checks-object = import ./profiles/update-checks-object.nix;
  };

  supportedForks = {
    # vscode = pkgs.vscode;
    # vscodium = pkgs.vscodium;
    # vscode-server = pkgs.openvscode-server;
    # vscode-insiders = pkgs.vscode-insiders;

    code-cursor = pkgs.code-cursor;
    kiro = pkgs.kiro;
    windsurf = pkgs.windsurf;
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

  singleProfilePackages = lib.mapAttrs (
    packageName: package: mkPackageWithVersion packageName "1.73.0"
  ) supportedForks;

  multiProfilePackages = lib.mapAttrs (
    packageName: package: mkPackageWithVersion packageName "1.74.0"
  ) supportedForks;

  buildTest =
    testName: forkConfig: testModule:
    lib.nameValuePair "vscode-forks-${forkConfig.package.pname}-${testName}" (testModule {
      inherit lib pkgs;

      forkInputs = forkConfig // {
        enable = true;
      };
    });

  buildTestSuite =
    groupName: forkConfig: testModules:
    lib.mapAttrs' (
      testName: testModule: buildTest "${groupName}-${testName}" forkConfig testModule
    ) testModules;

  buildTestSuiteForPackages =
    groupName: forkConfig: packages:
    lib.foldl' (acc: pkgTests: acc // pkgTests) { } (
      lib.attrValues (
        lib.mapAttrs (
          packageName: package:
          buildTestSuite groupName (forkConfig // { inherit package packageName; }) testModules
        ) packages
      )
    );

  singleProfileTests = buildTestSuiteForPackages "single-profile" { } singleProfilePackages;
  multiProfileTests = buildTestSuiteForPackages "multi-profile" { } multiProfilePackages;

  mutableProfileTests = buildTestSuiteForPackages "mutable-profile" {
    mutableProfile = true;
  } multiProfilePackages;

  immutableProfileTests = buildTestSuiteForPackages "immutable-profile" {
    mutableProfile = false;
  } multiProfilePackages;

  # knownTests = lib.mapAttrs' (k: v: lib.nameValuePair "vscode-${k}-known" (v knownPackage)) tests;
  # unknownTests = lib.mapAttrs' (k: v: lib.nameValuePair "vscode-${k}-unknown" (v unknownPackage)) tests;

  individualTests = lib.listToAttrs [
    # (buildTest "my-individual-test" {
    #   package = multiProfilePackages.code-cursor;
    #   packageName = "code-cursor";
    # } testModules.profiles-full)
  ];

  fullTestSuite = lib.foldl' (acc: tests: acc // tests) { } [
    individualTests
    singleProfileTests
    multiProfileTests
    mutableProfileTests
    immutableProfileTests
  ];
in
fullTestSuite
