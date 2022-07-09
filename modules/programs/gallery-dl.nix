{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.gallery-dl;

  jsonFormat = pkgs.formats.json { };

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.gallery-dl = {
    enable = mkEnableOption "gallery-dl";

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
        <filename>$XDG_CONFIG_HOME/gallery-dl/config.json</filename>. See
        <link xlink:href="https://github.com/mikf/gallery-dl#configuration"/>
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gallery-dl ];

    xdg.configFile."gallery-dl/config.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "gallery-dl-settings" cfg.settings;
    };
  };
}
