{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.python.pytest;
in {
  options.programs.python.pytest = {
    enable = mkEnableOption "pytest";
    package =
      mkPackageOption config.programs.python.pythonPackages "pytest" { };
  };
  config = { programs.python.packages = mkIf cfg.enable (_: [ cfg.package ]); };
}
