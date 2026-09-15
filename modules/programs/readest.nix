{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    types
    ;
in
{
  meta.maintainers = [ lib.maintainers.nyxar77 ];
  options.programs.readest = {
    enable = mkEnableOption "Readest";
    package = mkPackageOption pkgs "readest" { nullable = true; };

    settings = mkOption {
      type = types.nullOr (types.either types.path types.lines);
      default = null;
      example = lib.literalExpression ''
                {
          "telemetryEnabled": false,
          "libraryViewMode": "grid",
          "globalViewSettings": {
            "theme": "dark",
            "defaultFontSize": 18,
            "lineHeight": 1.5
          }
        }
        '''
      '';
      description = ''
          Readest configuration as either a path to a JSON file or literal JSON
        content. The configuration is written to
        {file}`$XDG_CONFIG_HOME/com.bilingify.readest/settings.json`.
      '';
    };
  };

  config =
    let
      cfg = config.programs.readest;
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      xdg.configFile."com.bilingify.readest/settings.json" = mkIf (cfg.settings != null) {
        source =
          if builtins.isPath cfg.settings then cfg.settings else pkgs.writeText "settings.json" cfg.settings;
      };
    };
}
