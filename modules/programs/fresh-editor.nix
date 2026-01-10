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

  cfg = config.programs.fresh-editor;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.maintainers; [ drupol ];
  options.programs.fresh-editor = {
    enable = mkEnableOption "fresh-editor";
    package = mkPackageOption pkgs "fresh-editor" { nullable = true; };
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        version = 1;
        theme = "dark";
        editor = {
          tab_size = 4;
          line_numbers = true;
        };
      };
      description = ''
        Configuration settings for fresh-editor. Find more configuration options in the user guide at:
        <https://github.com/sinelaw/fresh/blob/master/docs/USER_GUIDE.md>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."fresh/config.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "config.json" cfg.settings;
    };
  };
}
