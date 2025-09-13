{ lib, pkgs, ... }:
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
      packageName = "code-cursor"; # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/co/code-cursor/package.nix#L43

      # configDirectory = ".cursor";
      # userDirectory = "Cursor";

      overridePaths = {
        mcp = ".cursor";
      };
    })
  ];
}
