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

  generateConfig = lib.generators.toINIWithGlobalSection { };
  settingsType = with types; attrsOf str;
  criteriaType = types.attrsOf settingsType;
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
    [
      (lib.mkRemovedOptionModule [
        "services"
        "mako"
        "extraConfig"
      ] "Use services.mako.settings instead.")
      (lib.mkRenamedOptionModule [ "services" "mako" "criterias" ] [ "services" "mako" "criteria" ])
    ]
    ++ mkSettingsRenamedOptionModules basePath (basePath ++ [ "settings" ]) renamedOptions;

  options.services.mako = {
    enable = mkEnableOption "mako";
    package = mkPackageOption pkgs "mako" { };
    settings = mkOption {
      type = settingsType;
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
    criteria = mkOption {
      type = criteriaType;
      default = { };
      example = {
        "actionable=true" = {
          anchor = "top-left";
        };

        "app-name=Google\\ Chrome" = {
          max-visible = "5";
        };

        "field1=value field2=value" = {
          text-alignment = "left";
        };
      };
      description = ''
        Criterias for mako's config. All the details can be found in the
        CRITERIA section in the official documentation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mako" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."mako/config" = mkIf (cfg.settings != { } || cfg.criteria != { }) {
      onChange = "${cfg.package}/bin/makoctl reload || true";
      text = generateConfig {
        globalSection = cfg.settings;
        sections = cfg.criteria;
      };
    };
  };
}
