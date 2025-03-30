{ config, lib, pkgs, ... }:
let
  cfg = config.programs.sqls;

  yamlFormat = pkgs.formats.yaml { };
in {
  meta.maintainers = [ ];

  options.programs.sqls = {
    enable = lib.mkEnableOption "sqls, a SQL language server written in Go";

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
           lowercaseKeywords = true;
           connections = [
             {
               driver = "mysql";
               dataSourceName = "root:root@tcp(127.0.0.1:13306)/world";
             }
           ];
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/sqls/config.yml`. See
        <https://github.com/lighttiger2505/sqls#db-configuration>
        for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.sqls ];

    xdg.configFile."sqls/config.yml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "sqls-config" cfg.settings;
    };
  };
}
