{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkVSCodeFork = import ./vscode/mkVSCodeFork.nix;
in
{
  meta.maintainers = [ lib.maintainers.emaiax ];

  imports = [
    (mkVSCodeFork {
      modulePath = [
        "programs"
        "cursor"
      ];

      name = "Cursor";
      package = pkgs.code-cursor;
      packageName = "code-cursor";

      # Cursor stores MCP files in ~/.cursor
      #
      overridePaths = {
        mcp = "${config.home.homeDirectory}/.cursor";
      };
    })
  ];
}
