{
  config,
  lib,
  pkgs,
  ...
}@inputs:
let
  # packages: packageName -> package
  #
  supportedForks = {
    code-cursor = pkgs.code-cursor;
    kiro = pkgs.kiro;
    windsurf = pkgs.windsurf;
  };
in
{
  meta.maintainers = [ lib.hm.maintainers.emaiax ];

  imports = lib.mapAttrsToList (
    packageName: package: import ./vscode/mkVSCodeFork.nix (inputs // { inherit package packageName; })
  ) supportedForks;
}
