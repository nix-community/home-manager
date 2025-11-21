{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.gallery-dl;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ ];

  options.programs.gallery-dl = {
    enable = lib.mkEnableOption "gallery-dl";

    package = lib.mkPackageOption pkgs "gallery-dl" { nullable = true; };

    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          extractor.base-directory = "~/Downloads";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/gallery-dl/config.json`. See
        <https://github.com/mikf/gallery-dl#configuration>
        for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."gallery-dl/config.json" = lib.mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "gallery-dl-settings" cfg.settings;
    };
  };
}
