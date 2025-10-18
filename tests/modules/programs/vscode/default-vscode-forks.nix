{ lib, pkgs, ... }:
let
  supportedForks = {
    code-cursor = pkgs.code-cursor;
    # kiro = pkgs.kiro;
    # windsurf = pkgs.windsurf;
  };

  # currently only applies to Cursor and Windsurf
  #
  singleProfilePackageVersion = "1.75.0";
  multipleProfilePackageVersion = "1.74.0";

  mkPackageWithVersion =
    packageName: version:
    pkgs.writeScriptBin packageName ""
    // {
      inherit version;
      inherit (supportedForks.${packageName}) executableName longName pname;
    };

  singleProfilePackages = lib.mapAttrs (
    packageName: fork: mkPackageWithVersion packageName singleProfilePackageVersion
  ) supportedForks;

  multipleProfilePackages = lib.mapAttrs (
    packageName: fork: mkPackageWithVersion packageName multipleProfilePackageVersion
  ) supportedForks;

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

  # tests = {
  #   keybindings = import ./keybindings.nix;
  #   tasks = import ./tasks.nix;
  #   mcp = import ./mcp.nix;
  #   update-checks = import ./update-checks.nix;
  #   snippets = import ./snippets.nix;
  # };

  # knownTests = lib.mapAttrs' (k: v: lib.nameValuePair "vscode-${k}-known" (v knownPackage)) tests;
  # unknownTests = lib.mapAttrs' (
  #   k: v: lib.nameValuePair "vscode-${k}-unknown" (v unknownPackage)
  # ) tests;
  tests = {
    empty-profiles = import ./profiles/empty-profiles.nix;
    full-profiles = import ./profiles/full-profiles.nix;
    keybindings-immutable = import ./profiles/keybindings-immutable.nix;
    keybindings-mutable = import ./profiles/keybindings-mutable.nix;
    mcp-immutable = import ./profiles/mcp-immutable.nix;
    mcp-mutable = import ./profiles/mcp-mutable.nix;
    settings-immutable = import ./profiles/settings-immutable.nix;
    settings-mutable = import ./profiles/settings-mutable.nix;
    snippets-immutable = import ./profiles/snippets-immutable.nix;
    snippets-mutable = import ./profiles/snippets-mutable.nix;
    tasks-immutable = import ./profiles/tasks-immutable.nix;
    tasks-mutable = import ./profiles/tasks-mutable.nix;
  };

  buildTestListForPackage =
    packageName: package:
    lib.mapAttrs' (
      testName: module:
      lib.nameValuePair "vscode-factory-${package.pname}-${testName}" (module {
        inherit package packageName;

        enable = true;
      })
    ) tests;

  singleProfileTests =
    let
      result = lib.mapAttrs buildTestListForPackage singleProfilePackages;
      flattened = lib.foldl' (acc: tests: acc // tests) { } (lib.attrValues result);
    in
    # builtins.trace "singleProfileTests: ${builtins.toJSON result}" flattened;
    flattened;

  multipleProfileTests =
    let
      result = lib.mapAttrs buildTestListForPackage multipleProfilePackages;
      flattened = lib.foldl' (acc: tests: acc // tests) { } (lib.attrValues result);
    in
    # builtins.trace "multipleProfileTests: ${builtins.toJSON result}" flattened;
    flattened;

  # knownTests = lib.mapAttrs' (k: v: lib.nameValuePair "vscode-${k}-known" (v knownPackage)) tests;
  # unknownTests = lib.mapAttrs' (k: v: lib.nameValuePair "vscode-${k}-unknown" (v unknownPackage)) tests;

in
singleProfileTests // multipleProfileTests

# {
#   "vscode-factory-cursor-snippets-immutable" = import ./snippets/immutable.nix {
#     inherit lib pkgs;

#     package = multipleProfilePackages.code-cursor;
#     packageName = "code-cursor"; # custom package name is required because code-cursor.pname = "cursor"
#   };
# }
