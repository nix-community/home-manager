{ pkgs, lib, ... }:

let
  knownPackage = pkgs.writeScriptBin "vscode" "" // {
    pname = "vscode";
    version = "1.75.0";
  };

  unknownPackage = pkgs.writeTextFile rec {
    name = "${derivationArgs.pname}-${derivationArgs.version}";
    derivationArgs = {
      pname = "test-vscode-unknown";
      version = "0.1.0";
    };
    text = builtins.toJSON {
      dataFolderName = ".test-vscode-unknown";
      nameShort = passthru.longName;
    };
    destination = "/lib/vscode/resources/app/product.json";
    passthru.longName = "Test VSCode Fork";
  };

  tests = {
    argv = import ./argv.nix;
    keybindings = import ./keybindings.nix;
    tasks = import ./tasks.nix;
    mcp = import ./mcp.nix;
    update-checks = import ./update-checks.nix;
    snippets = import ./snippets.nix;
  };

  knownTests = lib.mapAttrs' (k: v: lib.nameValuePair "vscode-${k}-known" (v knownPackage)) tests;
  unknownTests = lib.mapAttrs' (
    k: v: lib.nameValuePair "vscode-${k}-unknown" (v unknownPackage)
  ) tests;
in

knownTests // unknownTests
