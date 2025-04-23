{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.programs.vesktop;
  jsonFormat = pkgs.formats.json { };

in
{
  meta.maintainers = [
    lib.maintainers.Flameopathic
    lib.hm.maintainers.LilleAila
  ];

  options.programs.vesktop = {
    enable = lib.mkEnableOption "Vesktop, an alternate client for Discord with Vencord built-in";
    package = lib.mkPackageOption pkgs "vesktop" { };
    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      description = ''
        Vesktop settings written to
        {file}`$XDG_CONFIG_HOME/vesktop/settings.json`. See
        <https://github.com/Vencord/Vesktop/blob/main/src/shared/settings.d.ts>
        for available options.
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

    vencord = {
      useSystem = lib.mkEnableOption "Vencord package from Nixpkgs";
      themes = lib.mkOption {
        description = ''
          Themes to add for Vencord, they can be enabled by setting
          `programs.vesktop.vencord.settings.enabledThemes` to `[ "THEME_NAME.css" ]`
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
          Vencord settings written to
          {file}`$XDG_CONFIG_HOME/vesktop/settings/settings.json`. See
          <https://github.com/Vendicated/Vencord/blob/main/src/api/Settings.ts>
          for available options.
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
    };
  };

  config = lib.mkIf cfg.enable (
    let
      config =
        lib.attrsets.unionOfDisjoint
          {
            "vesktop/settings.json".source = jsonFormat.generate "vesktop-settings" cfg.settings;
            "vesktop/settings/settings.json".source =
              jsonFormat.generate "vencord-settings" cfg.vencord.settings;
          }
          (
            lib.mapAttrs' (
              name: value:
              lib.nameValuePair "vesktop/themes/${name}.css" {
                source =
                  if builtins.isPath value || lib.isStorePath value then
                    value
                  else
                    pkgs.writeText "vesktop-themes-${name}" value;
              }
            ) cfg.vencord.themes
          );
    in
    lib.mkMerge [
      {
        home.packages = [
          (cfg.package.override { withSystemVencord = cfg.vencord.useSystem; })
        ];
      }
      (lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) { xdg.configFile = config; })
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        home.file = lib.mapAttrs' (n: v: lib.nameValuePair "Library/Application Support/${n}" v) config;
      })
    ]
  );
}
