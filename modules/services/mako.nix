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

  generateConfig =
    config:
    let
      formatValue = v: if builtins.isBool v then if v then "true" else "false" else toString v;

      globalSettings = lib.filterAttrs (n: v: !(lib.isAttrs v)) config;
      sectionSettings = lib.filterAttrs (n: v: lib.isAttrs v) config;

      globalLines = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (k: v: "${k}=${formatValue v}") globalSettings
      );

      formatSection =
        name: attrs:
        "\n[${name}]\n"
        + lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${formatValue v}") attrs);

      sectionLines = lib.concatStringsSep "\n" (lib.mapAttrsToList formatSection sectionSettings);
    in
    if sectionSettings != { } then globalLines + "\n" + sectionLines + "\n" else globalLines + "\n";

  iniFormat = pkgs.formats.ini { };
  iniType = iniFormat.type;
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
      type = lib.types.attrsOf (
        lib.types.oneOf [
          iniAtomType
          (lib.types.attrsOf iniAtomType)
        ]
      );
      default = { };
      example = ''
        {
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
        }
      '';
      description = ''
        Configuration settings for mako. Can include both global settings and sections.
        All available options can be found here:
        <https://github.com/emersion/mako/blob/master/doc/mako.5.scd>.
      '';
    };
    criteria = mkOption {
      visible = false;
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
        Criteria for mako's config. All the details can be found in the
        CRITERIA section in the official documentation.

        *Deprecated*: Use `settings` with nested attributes instead. For example:
        ```nix
        settings = {
          # Global settings
          anchor = "top-right";

          # Criteria sections
          "actionable=true" = {
            anchor = "top-left";
          };
        };
        ```
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mako" pkgs lib.platforms.linux)
    ];

    warnings = lib.optional (cfg.criteria != { }) ''
      The option `services.mako.criteria` is deprecated and will be removed in a future release.
      Please use `services.mako.settings` with nested attributes instead.

      For example, instead of:
        criteria = {
          "actionable=true" = {
            anchor = "top-left";
          };
        };

      Use:
        settings = {
          # Global settings here...

          # Criteria sections
          "actionable=true" = {
            anchor = "top-left";
          };
        };
    '';

    home.packages = [ cfg.package ];

    xdg.configFile."mako/config" = mkIf (cfg.settings != { } || cfg.criteria != { }) {
      onChange = "${cfg.package}/bin/makoctl reload || true";
      text =
        let
          # Merge settings and criteria into a single attribute set
          # where settings are at the top level and criteria are nested attributes
          mergedConfig = cfg.settings // cfg.criteria;
        in
        generateConfig mergedConfig;
    };
  };
}
