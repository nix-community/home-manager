{
  config,
  lib,
  pkgs,
  ...
}@inputs:
let
  forks = [
    {
      moduleName = "cursor";
      packageName = "code-cursor";
      package = if pkgs ? code-cursor then pkgs.code-cursor else null;
    }
    {
      moduleName = "kiro";
      packageName = "kiro";
      package = if pkgs ? kiro then pkgs.kiro else null;
    }
    {
      moduleName = "windsurf";
      packageName = "windsurf";
      package = if pkgs ? windsurf then pkgs.windsurf else null;
    }
  ];
in
{
  meta.maintainers = [ lib.hm.maintainers.emaiax ];

  imports = lib.map (fork: import ./vscodeFork.nix (inputs // fork)) forks;
}
