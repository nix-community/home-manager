{ lib, pkgs, ... }:
let
  mkVSCodeFork = import ./mkVSCodeFork.nix;
in
{
  meta.maintainers = [ lib.maintainers.emaiax ];

  imports = [
    (mkVSCodeFork {
      modulePath = [
        "programs"
        "vscode"
      ];

      name = "VSCode";
      package = pkgs.vscode;

      configDirName = "Code";
    })
  ];
}
