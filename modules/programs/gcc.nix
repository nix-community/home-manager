{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.gcc;

in
{

  meta.maintainers = [ lib.maintainers.bmrips ];

  options.programs.gcc = {
    enable = lib.mkEnableOption "{command}`gcc`.";
    package = lib.mkPackageOption pkgs "gcc" { nullable = true; };
    colors = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      description = "Settings for {env}`GCC_COLORS`";
      example = {
        error = "01;31";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    home.sessionVariables.GCC_COLORS = lib.mkIf (cfg.colors != { }) (
      lib.concatStringsSep ":" (lib.mapAttrsToList (n: v: "${n}=${v}") cfg.colors)
    );
  };

}
