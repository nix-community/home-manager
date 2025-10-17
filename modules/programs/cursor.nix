{
  config,
  lib,
  pkgs,
  ...
}@inputs:
let
  # forks: packageName -> package
  #
  supportedForks = {
    code-cursor = {
      package = pkgs.code-cursor;
      packageName = "code-cursor";
    };

    kiro.package = pkgs.kiro;
    windsurf.package = pkgs.windsurf;
  };
in
{
  meta.maintainers = [ lib.maintainers.emaiax ];

  imports = lib.mapAttrsToList (
    packageName: fork: import ./vscode/mkVSCodeFork.nix (inputs // fork)
  ) supportedForks;
}
