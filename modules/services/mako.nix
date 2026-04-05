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

  iniFormat = pkgs.formats.iniWithGlobalSection { listsAsDuplicateKeys = true; };
  iniAtomType = iniFormat.lib.types.atom;
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
        "criterias"
      ] "Use services.mako.settings instead.")
      (lib.mkRemovedOptionModule [
        "services"
        "mako"
        "criteria"
      ] "Use services.mako.settings instead.")
      (lib.mkRemovedOptionModule [
        "services"
        "mako"
        "extraConfig"
      ] "Use services.mako.settings.include instead.")
    ]
    ++ lib.hm.deprecations.mkSettingsRenamedOptionModules basePath (basePath ++ [ "settings" ]) {
      transform = lib.hm.strings.toKebabCase;
    } renamedOptions;

  options.services.mako = {
    enable = mkEnableOption "mako";
    package = mkPackageOption pkgs "mako" { };
    settings = mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          iniAtomType
          (lib.types.attrsOf iniAtomType)
        ]
      );
      default = { };
      example = {
        actions = true;
        anchor = "top-right";
        background-color = "#000000";
        border-color = "#FFFFFF";
        border-radius = 0;
        default-timeout = 0;
        font = "monospace 10";
        height = 100;
        width = 300;
        icons = true;
        ignore-timeout = false;
        layer = "top";
        margin = 10;
        markup = true;

        # Section example
        "actionable=true" = {
          anchor = "top-left";
        };
      };
      description = ''
        Configuration settings for mako. Can include both global settings and sections.
        All available options can be found here:
        <https://github.com/emersion/mako/blob/master/doc/mako.5.scd>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mako" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    dbus.packages = [ cfg.package ];

    xdg.configFile."mako/config" = mkIf (cfg.settings != { } || cfg.extraConfig != "") {
      onChange = "${cfg.package}/bin/makoctl reload || true";
      source = iniFormat.generate "mako-config" {
        globalSection = lib.filterAttrs (name: value: builtins.typeOf value != "set") cfg.settings;
        sections = lib.filterAttrs (name: value: builtins.typeOf value == "set") cfg.settings;
      };
    };
  };
}
