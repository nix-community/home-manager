{ pkgs, lib, ... }:

let
  package = pkgs.writeScriptBin "vscode" "" // {
    pname = "vscode";
    version = "1.75.0";
  };

  tests = {
    argv = import ./argv.nix;
    keybindings = import ./keybindings.nix;
    tasks = import ./tasks.nix;
    mcp = import ./mcp.nix;
    mcp-integration = import ./mcp-integration.nix;
    mcp-integration-with-override = import ./mcp-integration-with-override.nix;
    update-checks = import ./update-checks.nix;
    snippets = import ./snippets.nix;
  };

  nullPackageTests = {
    vscode-null-package = import ./null-package.nix;
  };
in

lib.mapAttrs' (k: v: lib.nameValuePair "vscode-${k}" (v package)) tests // nullPackageTests
