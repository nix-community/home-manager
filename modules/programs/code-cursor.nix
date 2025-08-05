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

      multiProfile = false;

      platforms.darwin = {
        mcpPath = "${config.home.homeDirectory}/.cursor";
        tasksPath = "${config.home.homeDirectory}/.cursor";
      };
    })
  ];
}
