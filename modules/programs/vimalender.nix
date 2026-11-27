{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.vimalender;
in
{
  meta.maintainers = [ lib.hm.maintainers.sand4rt ];

  options.programs.vimalender = {
    enable = lib.mkEnableOption "vimalender, a vim-style terminal calendar";

    package = lib.mkPackageOption pkgs "vimalender" { nullable = true; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
  };
}
