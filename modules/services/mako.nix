{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.services.mako;

  generateConfig = lib.generators.toINIWithGlobalSection { };
  iniType = (pkgs.formats.ini { }).type;
  iniAtomType = (pkgs.formats.ini { }).lib.types.atom;
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
    in
    [
      (lib.mkRemovedOptionModule [
        "services"
        "mako"
        "extraConfig"
      ] "Use services.mako.settings instead.")
      (lib.mkRenamedOptionModule [ "services" "mako" "criterias" ] [ "services" "mako" "criteria" ])
    ]
    ++ lib.hm.deprecations.mkSettingsRenamedOptionModules basePath (basePath ++ [ "settings" ]) {
      transform = lib.hm.strings.toKebabCase;
    } renamedOptions;

  options.services.mako = {
    enable = mkEnableOption "mako";
    package = mkPackageOption pkgs "mako" { };
    settings = mkOption {
      type = lib.types.attrsOf iniAtomType;
      default = { };
      example = ''
        {
          actions = "true";
          anchor = "top-right";
          background-color = "#000000";
          border-color = "#FFFFFF";
          border-radius = "0";
          default-timeout = "0";
          font = "monospace 10";
          height = "100";
          width = "300";
          icons = "true";
          ignore-timeout = "false";
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
      type = iniType;
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
