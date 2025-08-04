{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.grep;

in
{

  meta.maintainers = [ lib.maintainers.bmrips ];

  options.programs.grep = {
    enable = lib.mkEnableOption "{command}`grep`.";
    package = lib.mkPackageOption pkgs "grep" {
      default = "gnugrep";
      nullable = true;
    };
    colors = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      description = "Settings for {env}`GREP_COLORS`";
      example.error = "01;31";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    home.sessionVariables.GREP_COLORS = lib.mkIf (cfg.colors != { }) (
      lib.concatStringsSep ":" (lib.mapAttrsToList (n: v: "${n}=${v}") cfg.colors)
    );
  };

}
