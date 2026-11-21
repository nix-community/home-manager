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

  jsonFormat = pkgs.formats.json { };
  cfg = config.programs.zapfast;
in
{
  meta.maintainers = [ lib.maintainers.cleboost ];

  options.programs.zapfast = {
    enable = mkEnableOption "zapfast";

    package = mkPackageOption pkgs "zapfast" { nullable = true; };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          theme = "dark";
          notifications = {
            enabled = true;
            sound = false;
          };
        }
      '';
      description = ''
        Configuration settings for ZapFast. Written to
        {file}`$XDG_CONFIG_HOME/zapfast/settings.json`.
        See <https://zapfast.rocks/settings-and-files/> for available options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."zapfast/settings.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "zapfast-settings.json" cfg.settings;
    };
  };
}
