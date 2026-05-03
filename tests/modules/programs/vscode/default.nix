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
    null-package = import ./null-package.nix;
    fork-package-warning = import ./fork-package-warning.nix;
  };

in

lib.mapAttrs' (k: v: lib.nameValuePair "vscode-${k}" (v package)) tests
