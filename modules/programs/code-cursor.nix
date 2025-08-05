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

      # Cursor stores MCP files in ~/.cursor instead of standard VSCode location
      # which conflicts when multiple profiles have mcp configs.
      #
      # We avoid this by only generating the default profile when fork is not `multiProfile`.
      #
      multiProfile = false;

      paths = {
        mcp = "${config.home.homeDirectory}/.cursor/mcp.json";
      };
    })
  ];
}
