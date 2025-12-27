{
  config,
  lib,
  pkgs,
  ...
}@inputs:
let
  forks = [
    { moduleName = "kiro"; }
    { moduleName = "vscode"; }
    { moduleName = "windsurf"; }
    {
      moduleName = "cursor";
      packageName = "code-cursor";
    }
    {
      moduleName = "vscodium";
      dataFolderName = ".vscode-oss";
    }
    {
      moduleName = "openvscode-server";
      dataFolderName = ".vscode-server";
    }
    {
      moduleName = "vscode-insiders";
      packageName = "vscode";
      isInsiders = true;
    }
  ];
in
{
  meta.maintainers = [ lib.maintainers.emaiax ];

  imports = lib.map (fork: import ./vscodeFork.nix (inputs // fork)) forks;
}
