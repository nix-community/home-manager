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

  cfg = config.programs.radio-cli;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.radio-cli = {
    enable = mkEnableOption "radio-cli";
    package = mkPackageOption pkgs "radio-cli" { nullable = true; };
    settings = mkOption {
      type = jsonFormat.type;
      default = { };
      example = {
        config_version = "2.3.0";
        max_lines = 7;
        country = "ES";
        data = [
          {
            station = "lofi";
            url = "https://www.youtube.com/live/jfKfPfyJRdk?si=WDl-XdfuhxBfe6XN";
          }
        ];
      };
      description = ''
        Configuration settings for radio-cli. For an example config,
        refer to: <https://github.com/margual56/radio-cli/blob/main/config.json>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."radio-cli/config.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "radio-cli-config" cfg.settings;
    };
  };
}
