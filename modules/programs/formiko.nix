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

  cfg = config.programs.formiko;
  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.formiko = {
    enable = mkEnableOption "formiko";
    package = mkPackageOption pkgs "formiko" { nullable = true; };
    settings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        main = {
          preview = 0;
          parser = "json";
          auto_scroll = true;
          writer = "tiny";
        };

        editor = {
          period_save = true;
          check_spelling = false;
          auto_indent = false;
        };
      };
      description = ''
        Configuration settings for formiko. All the available options
        can be found by looking at ~/.config/formiko.ini.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."formiko.ini" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "formiko.ini" cfg.settings;
    };
  };
}
