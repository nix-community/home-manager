{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.hyfetch;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.hm.maintainers.lilyinstarlight ];

  options.programs.hyfetch = {
    enable = lib.mkEnableOption "hyfetch";

    package = lib.mkPackageOption pkgs "hyfetch" { };

    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      example = lib.literalExpression ''
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

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."hyfetch.json" = lib.mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "hyfetch.json" cfg.settings;
    };
  };
}
