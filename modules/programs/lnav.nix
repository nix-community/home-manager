{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    literalExpression
    mapAttrs'
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.programs.lnav;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.hm.maintainers.takeokunn ];

  options.programs.lnav = {
    enable = mkEnableOption "lnav, the log file navigator";

    package = mkPackageOption pkgs "lnav" { nullable = true; };

    settings = mkOption {
      type = jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          ui = {
            theme = "dracula";
            clock-format = "%Y-%m-%d %H:%M";
          };
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/lnav/config.json`.
        See <https://docs.lnav.org/en/latest/config.html> for the documentation.
      '';
    };

    formats = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''
        {
          laravel = ./formats/laravel.json;
        }
      '';
      description = ''
        Custom log format files to install in
        {file}`$XDG_CONFIG_HOME/lnav/formats/installed/`.
        See <https://docs.lnav.org/en/latest/formats.html> for the documentation.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = mkMerge [
      (mkIf (cfg.settings != { }) {
        "lnav/config.json".source = jsonFormat.generate "lnav-config.json" cfg.settings;
      })

      (mkIf (cfg.formats != { }) (
        mapAttrs' (name: path: {
          name = "lnav/formats/installed/${name}.json";
          value.source = path;
        }) cfg.formats
      ))
    ];
  };
}
