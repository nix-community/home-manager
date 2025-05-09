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

  cfg = config.programs.onlyoffice;
  formatter = pkgs.formats.keyValue { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.onlyoffice = {
    enable = mkEnableOption "onlyoffice";

    package = mkPackageOption pkgs "onlyoffice-desktopeditors" { nullable = true; };

    settings = mkOption {
      type = formatter.type;
      default = { };
      example = ''
        UITheme = "theme-contrast-dark";
        editorWindowMode = false;
        forcedRtl = false;
        maximized = true;
        titlebar = "custom";
      '';
      description = ''
        Configuration settings for Onlyoffice.

        All configurable options can be deduced by enabling them through the
        GUI and observing the changes in ~/.config/onlyoffice/DesktopEditors.conf.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."onlyoffice/DesktopEditors.conf" = mkIf (cfg.settings != { }) {
      source = formatter.generate "onlyoffice-config" cfg.settings;
    };
  };
}
