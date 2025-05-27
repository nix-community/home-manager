{
  pkgs,
  config,
  lib,
  ...
}:

let

  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    literalExpression
    ;

  iniFormat = pkgs.formats.ini { };
  cfg = config.programs.pgcli;

in
{
  meta.maintainers = [ lib.hm.maintainers.nickthegroot ];

  options.programs.pgcli = {
    enable = mkEnableOption "pgcli";

    package = mkPackageOption pkgs "pgcli" { nullable = true; };

    settings = mkOption {
      type = iniFormat.type;
      default = { };
      example = literalExpression ''
        {
          main = {
            smart_completion = true;
            vi = true;
          };

          "named queries".simple = "select * from abc where a is not Null";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/pgcli/config`.
        See <https://www.pgcli.com/config>
        for more information.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."pgcli/config" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "pgcli-config" cfg.settings;
    };
  };
}
