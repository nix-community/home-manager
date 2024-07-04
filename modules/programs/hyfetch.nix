{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.hyfetch;

  jsonFormat = pkgs.formats.json { };
in {
  meta.maintainers = [ hm.maintainers.lilyinstarlight ];

  options.programs.hyfetch = {
    enable = mkEnableOption "hyfetch";

    package = mkOption {
      type = types.package;
      default = pkgs.hyfetch;
      defaultText = literalExpression "pkgs.hyfetch";
      description = "The hyfetch package to use.";
    };

    settings = mkOption {
      type = jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          preset = "rainbow";
          mode = "rgb";
          color_align = {
            mode = "horizontal";
          };
        }
      '';
      description = "JSON config for HyFetch";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."hyfetch.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "hyfetch.json" cfg.settings;
    };
  };
}
