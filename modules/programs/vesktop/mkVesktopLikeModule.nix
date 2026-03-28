{
  # programs.${moduleName}
  moduleName,
  # for vesktop it is vencord, equibop -> equicord
  cordModuleName,
  # all config options link
  allConfigOptionsLink,
  # all config options link for ${cordModuleName}
  allCordConfigOptionsLink,
  # whether to add package to home.packages
  installPackage,
  # meta.maintainers
  maintainers,
}:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.${moduleName};
  cordCfg = config.programs.${moduleName}.${cordModuleName};
  package = pkgs.${moduleName};
  jsonFormat = pkgs.formats.json { };

  reprName = lib.toSentenceCase moduleName;
  cordReprName = lib.toSentenceCase cordModuleName;
in
{
  meta.maintainers = maintainers;

  options.programs.${moduleName} = {
    enable = lib.mkEnableOption package.meta.description;
    package = lib.mkPackageOption pkgs moduleName { };
    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      description = ''
        ${reprName} settings written to
        {file}`$XDG_CONFIG_HOME/${moduleName}/settings.json`. See
        <${allConfigOptionsLink}> for available options.
      '';
      example = lib.literalExpression ''
        {
          appBadge = false;
          arRPC = true;
          checkUpdates = false;
          customTitleBar = false;
          disableMinSize = true;
          minimizeToTray = false;
          tray = false;
          splashBackground = "#000000";
          splashColor = "#ffffff";
          splashTheming = true;
          staticTitle = true;
          hardwareAcceleration = true;
          discordBranch = "stable";
        }
      '';
    };

    ${cordModuleName} = {
      themes = lib.mkOption {
        description = ''
          Themes to add for ${cordReprName}, they can be enabled by setting
          `programs.${moduleName}.${cordModuleName}.settings.enabledThemes`
          to `[ "THEME_NAME.css" ]`
        '';
        default = { };
        type =
          with lib.types;
          attrsOf (oneOf [
            lines
            path
          ]);
      };
      settings = lib.mkOption {
        type = jsonFormat.type;
        default = { };
        description = ''
          ${cordReprName} settings written to
          {file}`$XDG_CONFIG_HOME/${moduleName}/settings/settings.json`. See
          <${allCordConfigOptionsLink}> for available options.
        '';
        example = lib.literalExpression ''
          {
            autoUpdate = false;
            autoUpdateNotification = false;
            notifyAboutUpdates = false;
            useQuickCss = true;
            disableMinSize = true;
            plugins = {
              MessageLogger = {
                enabled = true;
                ignoreSelf = true;
              };
              FakeNitro.enabled = true;
            };
          }
        '';
      };
      extraQuickCss = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Additional CSS rules.
        '';
        example = ''
          /* disable webcam preview mirroring */
          .media-engine-video { transform: none; }
        '';
      };
    };
  };

  config =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;

      configFiles =
        lib.attrsets.unionOfDisjoint
          {
            "${moduleName}/settings.json" = lib.mkIf (cfg.settings != { }) {
              source = jsonFormat.generate "${moduleName}-settings" cfg.settings;
            };
            "${moduleName}/settings/settings.json" = lib.mkIf (cordCfg.settings != { }) {
              source = jsonFormat.generate "${cordModuleName}-settings" cordCfg.settings;
            };
            "${moduleName}/settings/quickCss.css" = lib.mkIf (cordCfg.extraQuickCss != "") {
              text = cordCfg.extraQuickCss;
            };
          }
          (
            lib.mapAttrs' (
              name: value:
              lib.nameValuePair "${moduleName}/themes/${name}.css" {
                source =
                  if builtins.isPath value || lib.isStorePath value then
                    value
                  else
                    pkgs.writeText "${moduleName}-themes-${name}" value;
              }
            ) cordCfg.themes
          );
    in
    lib.mkIf cfg.enable {
      home.packages = lib.mkIf installPackage [ cfg.package ];
      home.file = lib.mapAttrs' (n: lib.nameValuePair "${configDir}/${n}") configFiles;
    };
}
