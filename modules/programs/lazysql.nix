{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.lazysql;

  formatter = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.lazysql = {
    enable = mkEnableOption "lazysql";
    package = mkPackageOption pkgs "lazysql" { nullable = true; };
    settings = mkOption {
      type = formatter.type;
      default = { };
      example = { };
      description = ''
        Configuration settings for lazysql.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."lazysql/config.toml" = mkIf (cfg.settings != { }) {
      source = formatter.generate "lazysql-config" cfg.settings;
    };
  };
}
