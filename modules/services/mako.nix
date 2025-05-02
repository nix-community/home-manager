{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.services.mako;

  generateConfig = lib.generators.toKeyValue { };
in
{
  meta.maintainers = [ lib.maintainers.onny ];

  imports =
    let
      basePath = [
        "services"
        "mako"
      ];

      renamedOptions = [
        "maxVisible"
        "maxHistory"
        "sort"
        "output"
        "layer"
        "anchor"
        "font"
        "backgroundColor"
        "textColor"
        "width"
        "height"
        "margin"
        "padding"
        "borderSize"
        "borderColor"
        "borderRadius"
        "progressColor"
        "icons"
        "maxIconSize"
        "iconPath"
        "markup"
        "actions"
        "format"
        "defaultTimeout"
        "ignoreTimeout"
        "groupBy"
      ];

      mkSettingsRenamedOptionModules =
        oldPrefix: newPrefix:
        map (option: lib.mkRenamedOptionModule (oldPrefix ++ [ option ]) (newPrefix ++ [ option ]));
    in
    mkSettingsRenamedOptionModules basePath (basePath ++ [ "settings" ]) renamedOptions;

  options.services.mako = {
    enable = mkEnableOption "mako";
    package = mkPackageOption pkgs "mako" { };
    settings = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = ''
        {
          actions = "true";
          anchor = "top-right";
          backgroundColor = "#000000";
          borderColor = "#FFFFFF";
          borderRadius = "0";
          defaultTimeout = "0";
          font = "monospace 10";
          height = "100";
          width = "300";
          icons = "true";
          ignoreTimeout = "false";
          layer = "top";
          margin = "10";
          markup = "true";
        }
      '';
      description = ''
        Configuration settings for mako. All available options can be found
        here: <https://github.com/emersion/mako/blob/master/doc/mako.5.scd>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mako" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."mako/config" = mkIf (cfg.settings != { }) {
      onChange = "${cfg.package}/bin/makoctl reload || true";
      text = generateConfig cfg.settings;
    };
  };
}
