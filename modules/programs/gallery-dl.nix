{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.gallery-dl;

  jsonFormat = pkgs.formats.json { };

in {
  meta.maintainers = [ ];

  options.programs.gallery-dl = {
    enable = mkEnableOption "gallery-dl";

    package = mkPackageOption pkgs "gallery-dl" { };

    settings = mkOption {
      type = jsonFormat.type;
      default = { };
      example = literalExpression ''
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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."gallery-dl/config.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "gallery-dl-settings" cfg.settings;
    };
  };
}
