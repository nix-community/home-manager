{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nix-output-monitor;
in
{
  meta.maintainers = [ lib.maintainers.adda ];

  options.programs.nix-output-monitor = {
    enable = lib.mkEnableOption ''
      {command}`nix-output-monitor`. Pipe your nix-build output through the
      nix-output-monitor a.k.a nom to get additional information while building'';

    package = lib.mkPackageOption pkgs "nix-output-monitor" { };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
