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

  cfg = config.programs.retext;
  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.retext = {
    enable = mkEnableOption "retext";
    package = mkPackageOption pkgs "retext" { nullable = true; };
    settings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        General = {
          documentStatsEnabled = true;
          lineNumbersEnabled = true;
          relativeLineNumbers = true;
          useWebEngine = true;
        };

        ColorScheme = {
          htmlTags = "green";
          htmlSymbols = "#ff8800";
          htmlComments = "#abc";
        };
      };
      description = ''
        Configuration settings for retext. All the available options can be found
        here: <https://github.com/retext-project/retext/blob/master/configuration.md>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."ReText Project/ReText.conf" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "ReText.conf" cfg.settings;
    };
  };
}
